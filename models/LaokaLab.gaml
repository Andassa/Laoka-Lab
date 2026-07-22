/**
 * Laoka Lab — Simulation multi-agents "Inona ny laoka"
 * Point d'entree : global + experiments. Specs dans species/Entites + species/Agents.
 */
model LaokaLab

import "species/Entites.gaml"
import "species/Agents.gaml"

global {
	/* ----- Parametres UI ----- */
	string periode_simulation <- "semaine";
	int nb_households <- 6;
	int seuil_alerte_nutrition <- 5;
	float budget_initial_defaut <- 50000.0;
	float tolerance_depassement_budget <- 0.10;

	/* ----- Etat monde ----- */
	graph reseau_quartier;
	list catalogue_plats <- [];
	household foyer_selectionne;

	/* ----- Compteurs ----- */
	int nb_plans_sans_conflit <- 0;
	int nb_plans_avec_achat <- 0;
	int nb_alertes_nutritionnelles_total <- 0;
	int nb_repetitions_evitees <- 0;
	int nb_recours_magasin <- 0;
	float budget_moyen_consomme <- 0.0;
	float somme_budgets_consommes <- 0.0;

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

	action charger_plats {
		file f <- csv_file("../includes/plats.csv", true);
		matrix mat <- matrix(f);
		loop lig from: 0 to: mat.rows - 1 {
			create plat_item number: 1 returns: nouveaux {
				nom_plat <- "" + mat[0, lig];
				string raw_ing <- "" + mat[1, lig];
				list parts <- raw_ing split_with ";";
				list ings <- [];
				loop p over: parts {
					if p != nil and p != "" {
						ings <- ings + [p];
					}
				}
				ingredients <- ings;
				cout_estime <- float(mat[2, lig]);
				categorie_nutritionnelle <- "" + mat[3, lig];
				contient_porc <- (lower_case("" + mat[4, lig]) = "true");
				string raw_all <- "" + mat[5, lig];
				list alls <- [];
				if raw_all != "" and raw_all != "nil" {
					list ap <- raw_all split_with ";";
					loop a over: ap {
						if a != nil and a != "" {
							alls <- alls + [a];
						}
					}
				}
				allergenes <- alls;
				est_vegan <- (lower_case("" + mat[6, lig]) = "true");
			}
			catalogue_plats <- catalogue_plats + nouveaux;
		}
		write "Catalogue charge : " + length(catalogue_plats) + " plats";
	}

	action creer_environnement {
		create magasin number: 1 {
			nom <- "Shoprite Analakely";
			type_magasin <- "grande_surface";
			location <- {20.0, 20.0};
			produits_disponibles <- ["riz", "huile", "tomate", "oignon", "poulet", "porc", "boeuf", "poisson",
				"lait_coco", "haricot", "carotte", "pain", "fromage", "oeuf", "pates", "tofu", "chips", "soda"];
			prix <- ["riz"::2000.0, "huile"::3000.0, "tomate"::1000.0, "oignon"::800.0, "poulet"::6000.0,
				"porc"::5500.0, "boeuf"::7000.0, "poisson"::5000.0, "lait_coco"::2500.0, "haricot"::1500.0,
				"carotte"::1000.0, "pain"::1200.0, "fromage"::4000.0, "oeuf"::500.0, "pates"::2000.0,
				"tofu"::3500.0, "chips"::1500.0, "soda"::1000.0];
		}
		create magasin number: 1 {
			nom <- "Epicerie Isotry";
			type_magasin <- "epicerie_locale";
			location <- {80.0, 30.0};
			produits_disponibles <- ["riz", "huile", "tomate", "oignon", "brede", "feuilles_manioc", "haricot",
				"banane", "mangue", "lait", "sucre", "farine_riz"];
			prix <- ["riz"::1800.0, "huile"::2800.0, "tomate"::900.0, "oignon"::700.0, "brede"::500.0,
				"feuilles_manioc"::600.0, "haricot"::1400.0, "banane"::800.0, "mangue"::1000.0,
				"lait"::2000.0, "sucre"::1500.0, "farine_riz"::1800.0];
		}
		create magasin number: 1 {
			nom <- "SuperU Andraharo";
			type_magasin <- "grande_surface";
			location <- {50.0, 80.0};
			produits_disponibles <- ["riz", "huile", "poulet", "poisson", "fromage", "yaourt", "cereales",
				"chapelure", "mayonnaise", "saucisse_porc", "pain", "beurre", "confiture", "soja", "brocoli",
				"laitue", "concombre", "poivron", "courgette"];
			prix <- ["riz"::2100.0, "huile"::3200.0, "poulet"::6500.0, "poisson"::5500.0, "fromage"::4200.0,
				"yaourt"::1500.0, "cereales"::3500.0, "chapelure"::2000.0, "mayonnaise"::2500.0,
				"saucisse_porc"::4000.0, "pain"::1300.0, "beurre"::3000.0, "confiture"::2500.0,
				"soja"::2000.0, "brocoli"::2000.0, "laitue"::1000.0, "concombre"::800.0,
				"poivron"::1200.0, "courgette"::1000.0];
		}
		create salle_de_sport number: 1 {
			nom <- "Fitness Park Antaninarenina";
			location <- {40.0, 50.0};
		}
		create salle_de_sport number: 1 {
			nom <- "Dojo Mahamasina";
			location <- {70.0, 70.0};
		}
		create salle_de_sport number: 1 {
			nom <- "Gym Ivandry";
			location <- {15.0, 75.0};
		}
	}

	action construire_reseau {
		list noeuds <- list(magasin) + list(salle_de_sport) + list(household);
		reseau_quartier <- as_distance_graph(noeuds, 60.0);
	}

	action creer_personas {
		int n <- min(nb_households, 6);
		loop i from: 0 to: n - 1 {
			create household number: 1 {
				location <- {10.0 + rnd(80.0), 10.0 + rnd(80.0)};
				if i = 0 {
					nom_foyer <- "Foyer Malgache";
					storage_mode <- "etalage";
					nb_personnes <- 5;
					budget_periode <- 35000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("limite");
				} else if i = 1 {
					nom_foyer <- "Foyer Europeen";
					storage_mode <- "frigidaire";
					nb_personnes <- 1;
					budget_periode <- 80000.0;
					restrictions_culturelles <- [];
					allergies <- ["fruits_de_mer"];
					regime <- "equilibre";
					do initialiser_provisions("moyen");
				} else if i = 2 {
					nom_foyer <- "Foyer Sans Porc";
					storage_mode <- "panier";
					nb_personnes <- 3;
					budget_periode <- 50000.0;
					restrictions_culturelles <- ["pas_de_porc"];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("faible");
				} else if i = 3 {
					nom_foyer <- "Foyer Vegan";
					storage_mode <- "frigidaire";
					nb_personnes <- 2;
					budget_periode <- 30000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "vegan";
					do initialiser_provisions("riche");
				} else if i = 4 {
					nom_foyer <- "Foyer Defaut";
					storage_mode <- "etalage";
					nb_personnes <- 2;
					budget_periode <- budget_initial_defaut;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("moyen");
				} else {
					nom_foyer <- "Foyer Malbouffe";
					storage_mode <- "etalage";
					nb_personnes <- 1;
					budget_periode <- 60000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "malbouffe_assumee";
					do initialiser_provisions("moyen");
				}
				budget_restant <- budget_periode;
				do creer_agents_decision;
			}
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

	string concat_liste (list elems, string sep) {
		string s <- "";
		int i <- 0;
		loop e over: elems {
			if i > 0 {
				s <- s + sep;
			}
			s <- s + ("" + e);
			i <- i + 1;
		}
		return s;
	}

	reflex cycle_recommandation {
		nb_plans_sans_conflit <- 0;
		nb_plans_avec_achat <- 0;
		somme_budgets_consommes <- 0.0;
		ask household {
			do demander_plan;
			somme_budgets_consommes <- somme_budgets_consommes + (budget_periode - budget_restant);
			if necessite_achat {
				nb_plans_avec_achat <- nb_plans_avec_achat + 1;
			} else {
				nb_plans_sans_conflit <- nb_plans_sans_conflit + 1;
			}
		}
		if length(household) > 0 {
			budget_moyen_consomme <- somme_budgets_consommes / length(household);
		} else {
			budget_moyen_consomme <- 0.0;
		}
		do exporter_resultats;
		write "--- Cycle " + cycle
			+ " | sans conflit: " + nb_plans_sans_conflit
			+ " | avec achat: " + nb_plans_avec_achat
			+ " | alertes: " + nb_alertes_nutritionnelles_total
			+ " | budget moyen: " + budget_moyen_consomme + " ---";
	}

	action exporter_resultats {
		ask household {
			loop repas_map over: plan_courant {
				map rm <- map(repas_map);
				string ligne <- "" + cycle + ";" + nom_foyer + ";" + rm["type_repas"] + ";"
					+ rm["nom_plat"] + ";" + rm["cout"] + ";" + rm["justification"] + ";"
					+ rm["magasin_suggere"] + ";" + rm["salle_sport_suggeree"] + ";"
					+ rm["achat_necessaire"] + ";" + alertes_nutritionnelles;
				save ligne to: "../results/arbitrage_log.csv" format: "text" rewrite: false;
			}
		}
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
				draw world.shape color: rgb(245, 242, 235);
			}
			species magasin aspect: base;
			species salle_de_sport aspect: base;
			species household aspect: base;
			overlay position: {5 #px, 5 #px} size: {280 #px, 90 #px} background: #white transparency: 0.2 {
				draw "Maison = foyer | Magasin | Haltères = sport" at: {10 #px, 22 #px} color: #black size: 11 #px;
				draw "Couleur foyer: bleu / vert vegan / rouge malbouffe / violet sans porc" at: {10 #px, 44 #px} color: #black size: 10 #px;
				draw "Badge rouge = alertes nutritionnelles cumulees" at: {10 #px, 66 #px} color: #darkred size: 10 #px;
			}
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
	}
}

experiment ExportBatch type: batch repeat: 1 keep_seed: true until: (cycle >= 3) {
	parameter "Periode" var: periode_simulation among: ["jour", "semaine"];
}
