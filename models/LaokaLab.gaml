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

	household foyer_selectionne;

	init {
		do charger_plats;
		do creer_environnement;
		do creer_personas;
		do construire_reseau;
		foyer_selectionne <- first(household);
		save "cycle;nom_foyer;type_repas;nom_plat;cout;justification;magasin;salle_sport;achat;alertes"
			to: "../results/arbitrage_log.csv" format: "text" rewrite: true;
		write "=== Laoka Lab : " + length(household) + " foyers, "
			+ length(magasin) + " magasins, " + length(catalogue_plats) + " plats ===";
	}

	/* Surcharge des helpers (Agents fournit des stubs pour l'IDE). */
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
	parameter "Periode de simulation" var: periode_simulation among: ["jour", "semaine", "mois"] category: "Simulation";
	parameter "Nombre de foyers" var: nb_households min: 1 max: 6 category: "Simulation";
	parameter "Seuil alerte nutrition" var: seuil_alerte_nutrition min: 1 max: 20 category: "Nutrition";
	parameter "Budget initial defaut" var: budget_initial_defaut category: "Budget";
	parameter "Tolerance depassement budget" var: tolerance_depassement_budget category: "Budget";

	output {
		display "Carte du quartier" type: java2D {
			graphics "fond" {
				draw world.shape color: #white;
			}
			species magasin aspect: base;
			species salle_de_sport aspect: base;
			species household aspect: base;
		}
		display "Budget" type: 2d {
			chart "Budget moyen consomme" type: series {
				data "Budget moyen" value: budget_moyen_consomme color: #blue;
			}
		}
		display "Repetitions" type: 2d {
			chart "Repetitions evitees" type: series {
				data "Evitements" value: nb_repetitions_evitees color: #orange;
			}
		}
		display "Achats" type: 2d {
			chart "Recours magasin" type: series {
				data "Achats" value: nb_recours_magasin color: #red;
			}
		}
		display "Alertes" type: 2d {
			chart "Alertes nutritionnelles" type: series {
				data "Alertes cumulees" value: nb_alertes_nutritionnelles_total color: #purple;
			}
		}
		monitor "Periode" value: periode_simulation;
		monitor "Plans sans conflit" value: nb_plans_sans_conflit;
		monitor "Plans avec achat" value: nb_plans_avec_achat;
		monitor "Alertes nutrition (total)" value: nb_alertes_nutritionnelles_total;
		monitor "Budget moyen consomme" value: budget_moyen_consomme;
		monitor "Repetitions evitees" value: nb_repetitions_evitees;
		monitor "Recours magasin" value: nb_recours_magasin;
		monitor "Legende" value: "Disque+icone: foyer/magasin/sport | Label sous l'icone | Badge rouge = alertes";
	}
}

experiment ExportBatch type: batch repeat: 1 keep_seed: true until: (cycle >= 3) {
	parameter "Periode" var: periode_simulation among: ["jour", "semaine"];
}
