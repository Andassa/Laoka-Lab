/**
 * Laoka Lab — point d'entree.
 * Species : species/  | Init : global/InitMonde  | Cycle : global/CycleSimu
 */
model LaokaLab

import "species/Agents.gaml"
import "global/InitMonde.gaml"
import "global/CycleSimu.gaml"

global {
	string periode_simulation <- "semaine";
	int nb_households <- 6;
	int seuil_alerte_nutrition <- 5;
	float budget_initial_defaut <- 50000.0;
	float tolerance_depassement_budget <- 0.10;
	int pas_entre_plans <- 20;
	float vitesse_foyer <- 2.0;
	float qte_achat_pack <- 4.0;
	bool activer_deplacement <- false;
	bool afficher_icones <- true;
	int nb_plans_max <- 40;
	int nb_plans_faits <- 0;
	bool simulation_terminee <- false;
	string mode_budget <- "revenu";
	bool utiliser_negociation_scores <- true;
	float poids_budget <- 1.0;
	float poids_nutrition <- 1.0;
	float poids_stock <- 1.2;
	float poids_historique <- 0.8;

	household foyer_selectionne;

	init {
		do charger_plats;
		do creer_environnement;
		do creer_personas;
		do construire_reseau;
		ask household {
			position_maison <- location;
		}
		foyer_selectionne <- first(household);
		save "cycle;nom_foyer;type;plat_ou_resume;cout;detail;magasin;salle;achat;alertes"
			to: "../results/arbitrage_log.csv" format: "text" rewrite: true;
		save "cycle;plan;pct_stock;stock_moy;alertes;pct_malbouffe;pct_rejet_culture;pct_rejet_budget;evit_hist;nb_malbouffe;nb_equilibre;rejets_culture;rejets_budget"
			to: "../results/conflits_log.csv" format: "text" rewrite: true;
		write "=== Laoka Lab : " + length(household) + " foyers, "
			+ length(magasin) + " magasins, " + length(catalogue_plats) + " plats ===";
		write "Budget=" + mode_budget + " | Scores="
			+ (utiliser_negociation_scores ? "ON" : "OFF")
			+ " | Arret @" + nb_plans_max + " plans";
	}

	int calculer_nb_repas {
		if periode_simulation = "jour" {
			return 3;
		}
		if periode_simulation = "semaine" {
			return 21;
		}
		return 90;
	}

	string calculer_type_repas (int idx) {
		int modu <- idx mod 3;
		if modu = 0 {
			return "petit_dejeuner";
		}
		if modu = 1 {
			return "dejeuner";
		}
		return "diner";
	}
}

experiment LaokaLabUI type: gui {
	parameter "Periode" var: periode_simulation among: ["jour", "semaine", "mois"] category: "Simulation";
	parameter "Nb foyers" var: nb_households min: 1 max: 6 category: "Simulation";
	parameter "Nb plans max" var: nb_plans_max min: 10 max: 100 category: "Simulation";
	parameter "Pas entre plans" var: pas_entre_plans min: 5 max: 60 category: "Simulation";
	parameter "Mode budget" var: mode_budget among: ["revenu", "reset", "persist"] category: "Budget";
	parameter "Negociation par scores" var: utiliser_negociation_scores category: "Negociation";
	parameter "Poids budget" var: poids_budget min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids nutrition" var: poids_nutrition min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids stock" var: poids_stock min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids historique" var: poids_historique min: 0.0 max: 3.0 category: "Negociation";
	parameter "Activer deplacement" var: activer_deplacement category: "Affichage";
	parameter "Afficher icones" var: afficher_icones category: "Affichage";
	parameter "Vitesse deplacement" var: vitesse_foyer min: 0.5 max: 8.0 category: "Affichage";
	parameter "Seuil alerte nutrition" var: seuil_alerte_nutrition min: 1 max: 20 category: "Nutrition";
	parameter "Budget initial defaut" var: budget_initial_defaut category: "Budget";
	parameter "Tolerance budget" var: tolerance_depassement_budget category: "Budget";

	output {
		display "Carte" type: java2D refresh: every(15 #cycle) {
			graphics "fond" {
				draw world.shape color: #white;
			}
			species magasin aspect: base;
			species salle_de_sport aspect: base;
			species household aspect: base;
		}
		display "Stock %" type: 2d refresh: every(20 #cycle) {
			chart "% repas depuis stock" type: series {
				data "% stock" value: part_repas_stock color: #orange;
			}
		}
		display "Budget restant" type: 2d refresh: every(20 #cycle) {
			chart "Budget moyen restant" type: series {
				data "Budget restant" value: budget_moyen_restant color: #blue;
			}
		}
		display "Conflits" type: 2d refresh: every(20 #cycle) {
			chart "Pression des contraintes (%)" type: series {
				data "% rejet culture" value: pct_rejet_culture color: #purple;
				data "% rejet budget" value: pct_rejet_budget color: #blue;
				data "% malbouffe" value: pct_malbouffe color: #red;
			}
		}
		display "Alertes" type: 2d refresh: every(20 #cycle) {
			chart "Alertes nutrition (par plan)" type: series {
				data "Ce plan" value: nb_alertes_ce_cycle color: #tomato;
			}
		}
		monitor "Plans faits / max" value: "" + nb_plans_faits + " / " + nb_plans_max;
		monitor "Mode budget" value: mode_budget;
		monitor "Scores ON?" value: utiliser_negociation_scores;
		monitor "% repas stock" value: part_repas_stock;
		monitor "Budget moyen restant" value: budget_moyen_restant;
		monitor "% malbouffe" value: pct_malbouffe;
		monitor "% rejet culture" value: pct_rejet_culture;
		monitor "% rejet budget" value: pct_rejet_budget;
		monitor "Alertes ce plan" value: nb_alertes_ce_cycle;
		monitor "Foyer / plat" value: foyer_selectionne.nom_foyer + " | " + foyer_selectionne.dernier_plat;
		monitor "Astuce" value: "Deplacement OFF = pas de scintillement. Active-le seulement pour une demo.";
	}
}

/* Batch : config via init (evite les warnings among vs valeurs globales UI). */
experiment ScenarioBase type: batch repeat: 1 keep_seed: true until: simulation_terminee {
	init {
		periode_simulation <- "semaine";
		nb_plans_max <- 30;
		activer_deplacement <- false;
		seuil_alerte_nutrition <- 5;
		mode_budget <- "revenu";
		utiliser_negociation_scores <- true;
	}
}

experiment ScenarioSeuilStrict type: batch repeat: 1 keep_seed: true until: simulation_terminee {
	init {
		periode_simulation <- "semaine";
		nb_plans_max <- 30;
		activer_deplacement <- false;
		seuil_alerte_nutrition <- 3;
		mode_budget <- "revenu";
		utiliser_negociation_scores <- true;
	}
}

experiment ScenarioBudgetPersist type: batch repeat: 1 keep_seed: true until: simulation_terminee {
	init {
		periode_simulation <- "semaine";
		nb_plans_max <- 30;
		activer_deplacement <- false;
		seuil_alerte_nutrition <- 5;
		mode_budget <- "persist";
		utiliser_negociation_scores <- true;
	}
}

experiment ScenarioPipelineClassique type: batch repeat: 1 keep_seed: true until: simulation_terminee {
	init {
		periode_simulation <- "semaine";
		nb_plans_max <- 30;
		activer_deplacement <- false;
		seuil_alerte_nutrition <- 5;
		mode_budget <- "reset";
		utiliser_negociation_scores <- false;
	}
}
