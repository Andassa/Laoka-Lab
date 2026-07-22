/**
 * Initialisation du monde : catalogue, magasins, salles, personas, reseau.
 * Importe Agents (donc Entites). Fusionne dans LaokaLab via import.
 */
model InitMonde

import "../species/Agents.gaml"

global {
	list catalogue_plats <- [];
	graph reseau_quartier;
	int nb_households <- 6;
	float budget_initial_defaut <- 50000.0;

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
			label_carte <- "Shoprite";
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
			label_carte <- "Isotry";
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
			label_carte <- "SuperU";
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
			label_carte <- "Fitness";
			location <- {40.0, 50.0};
		}
		create salle_de_sport number: 1 {
			nom <- "Dojo Mahamasina";
			label_carte <- "Dojo";
			location <- {70.0, 70.0};
		}
		create salle_de_sport number: 1 {
			nom <- "Gym Ivandry";
			label_carte <- "Gym";
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
				if i = 0 {
					location <- {25.0, 45.0};
					nom_foyer <- "Foyer Malgache";
					label_carte <- "Malgache";
					storage_mode <- "etalage";
					nb_personnes <- 5;
					budget_periode <- 35000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("limite");
				} else if i = 1 {
					location <- {55.0, 25.0};
					nom_foyer <- "Foyer Europeen";
					label_carte <- "Europeen";
					storage_mode <- "frigidaire";
					nb_personnes <- 1;
					budget_periode <- 80000.0;
					restrictions_culturelles <- [];
					allergies <- ["fruits_de_mer"];
					regime <- "equilibre";
					do initialiser_provisions("moyen");
				} else if i = 2 {
					location <- {75.0, 55.0};
					nom_foyer <- "Foyer Sans Porc";
					label_carte <- "Sans porc";
					storage_mode <- "panier";
					nb_personnes <- 3;
					budget_periode <- 50000.0;
					restrictions_culturelles <- ["pas_de_porc"];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("faible");
				} else if i = 3 {
					location <- {35.0, 75.0};
					nom_foyer <- "Foyer Vegan";
					label_carte <- "Vegan";
					storage_mode <- "frigidaire";
					nb_personnes <- 2;
					budget_periode <- 30000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "vegan";
					do initialiser_provisions("riche");
				} else if i = 4 {
					location <- {60.0, 60.0};
					nom_foyer <- "Foyer Defaut";
					label_carte <- "Defaut";
					storage_mode <- "etalage";
					nb_personnes <- 2;
					budget_periode <- budget_initial_defaut;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("moyen");
				} else {
					location <- {85.0, 40.0};
					nom_foyer <- "Foyer Malbouffe";
					label_carte <- "Malbouffe";
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
}
