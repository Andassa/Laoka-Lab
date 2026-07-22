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
	int nb_households <- 8;
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
	float ratio_epargne_min <- 0.08;
	float taux_inflation <- 0.005;
	float multiplicateur_prix <- 1.0;
	int unites_perimees_total <- 0;
	bool utiliser_gis <- true;

	/* Shapefile OSM Antananarivo (routes) — ODbL, voir includes/gis/ATTRIBUTION.txt */
	shape_file fichier_routes <- shape_file("../includes/gis/antananarivo_roads.shp");
	/* Definir shape a la declaration (evite l'affectation dynamique en init). */
	geometry shape <- utiliser_gis ? envelope(fichier_routes) : square(100.0);

	household foyer_selectionne;

	init {
		if utiliser_gis {
			create route from: fichier_routes;
			write "GIS OSM : " + length(route) + " routes chargees (Antananarivo centre)";
		} else {
			write "GIS OFF : carte abstraite 100x100";
		}
		do charger_plats;
		do creer_environnement;
		do creer_personas;
		do construire_reseau;
		ask household {
			position_maison <- location;
		}
		foyer_selectionne <- first(household);
		save ("cycle;nom_foyer;type;plat_ou_resume;cout;detail;magasin;salle;achat;alertes" + "\n")
			to: "../results/arbitrage_log.csv" format: "text" rewrite: true;
		save ("cycle;plan;pct_stock;stock_moy;alertes;pct_malbouffe;pct_rejet_culture;pct_rejet_budget;evit_hist;nb_malbouffe;nb_equilibre;rejets_culture;rejets_budget" + "\n")
			to: "../results/conflits_log.csv" format: "text" rewrite: true;
		write "=== Laoka Lab : " + length(household) + " foyers, "
			+ length(magasin) + " magasins, " + length(catalogue_plats) + " plats ===";
		write "Budget=" + mode_budget + " | Scores="
			+ (utiliser_negociation_scores ? "ON" : "OFF")
			+ " | Epargne min=" + int(ratio_epargne_min * 100) + "%"
			+ " | Inflation=" + (round(taux_inflation * 1000) / 10) + "%/plan"
			+ " | GIS=" + (utiliser_gis ? "ON" : "OFF")
			+ " | Arret @" + nb_plans_max + " plans";
		write ">>> Regarde la fenetre CARTE : points orange=magasins, vert=salles, colores=foyers";
		ask household {
			write "  - " + nom_foyer + " @ " + location;
		}
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
	parameter "Nb foyers" var: nb_households min: 1 max: 8 category: "Simulation";
	parameter "Nb plans max" var: nb_plans_max min: 10 max: 100 category: "Simulation";
	parameter "Pas entre plans" var: pas_entre_plans min: 5 max: 60 category: "Simulation";
	parameter "Mode budget" var: mode_budget among: ["revenu", "reset", "persist"] category: "Budget";
	parameter "Epargne min (ratio)" var: ratio_epargne_min min: 0.0 max: 0.30 category: "Budget";
	parameter "Inflation / plan" var: taux_inflation min: 0.0 max: 0.05 category: "Budget";
	parameter "Negociation par scores" var: utiliser_negociation_scores category: "Negociation";
	parameter "Poids budget" var: poids_budget min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids nutrition" var: poids_nutrition min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids stock" var: poids_stock min: 0.0 max: 3.0 category: "Negociation";
	parameter "Poids historique" var: poids_historique min: 0.0 max: 3.0 category: "Negociation";
	parameter "Utiliser GIS OSM" var: utiliser_gis category: "Affichage";
	parameter "Activer deplacement" var: activer_deplacement category: "Affichage";
	parameter "Afficher icones" var: afficher_icones category: "Affichage";
	parameter "Vitesse deplacement" var: vitesse_foyer min: 0.00005 max: 8.0 category: "Affichage";
	parameter "Seuil alerte nutrition" var: seuil_alerte_nutrition min: 1 max: 20 category: "Nutrition";
	parameter "Budget initial defaut" var: budget_initial_defaut category: "Budget";
	parameter "Tolerance budget" var: tolerance_depassement_budget category: "Budget";

	output {
		display "Carte" type: java2D refresh: every(10 #cycle) {
			graphics "fond" {
				draw world.shape color: #white;
			}
			species route aspect: base;
			species quartier aspect: base;
			/* Dessin explicite en pixels : toujours lisible au-dessus des routes. */
			graphics "agents" {
				loop m over: magasin {
					draw circle(16#px) color: #orange border: #black at: m.location;
					draw m.label_carte color: #black font: font("Arial", 13, #bold) at: m.location + {0#px, 18#px};
				}
				loop s over: salle_de_sport {
					draw circle(16#px) color: #green border: #darkgreen at: s.location;
					draw s.label_carte color: #darkgreen font: font("Arial", 13, #bold) at: s.location + {0#px, 18#px};
				}
				loop h over: household {
					rgb col <- #steelblue;
					if h.regime = "vegan" {
						col <- #seagreen;
					} else if h.regime = "malbouffe_assumee" {
						col <- #tomato;
					} else if ("pas_de_porc" in h.restrictions_culturelles) {
						col <- #mediumpurple;
					}
					draw circle(18#px) color: col border: #black at: h.location;
					draw h.label_carte color: #black font: font("Arial", 13, #bold) at: h.location + {0#px, 20#px};
					if h.alertes_nutritionnelles > 0 {
						draw square(14#px) color: #red border: #white at: h.location + {14#px, -14#px};
						draw ("" + h.alertes_nutritionnelles) color: #white font: font("Arial", 11, #bold)
							at: h.location + {14#px, -14#px};
					}
				}
			}
			graphics "legende" {
				draw "Orange=magasin | Vert=salle | Couleurs=foyers" color: #dimgray
					font: font("Arial", 11, #bold) at: {5#px, 18#px};
			}
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
		monitor "GIS OSM" value: utiliser_gis ? ("" + length(route) + " routes") : "OFF";
		monitor "Agents carte" value: "" + length(household) + " foyers / "
			+ length(magasin) + " magasins / " + length(salle_de_sport) + " salles";
		monitor "Mode budget" value: mode_budget;
		monitor "Epargne min %" value: int(ratio_epargne_min * 100);
		monitor "Inflation cumul" value: "x" + (round(multiplicateur_prix * 100) / 100);
		monitor "Unites perimees" value: unites_perimees_total;
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
