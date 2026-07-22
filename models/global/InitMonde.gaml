/**
 * Initialisation du monde : catalogue, magasins, salles, personas, reseau.
 * Importe Agents (donc Entites). Fusionne dans LaokaLab via import.
 */
model InitMonde

import "../species/Agents.gaml"

global {
	list catalogue_plats <- [];
	graph reseau_quartier;
	int nb_households <- 8;
	float budget_initial_defaut <- 50000.0;
	bool utiliser_gis <- true;

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

	/* Fond pedagogique abstrait (si GIS OFF). */
	action creer_quartiers_abstraits {
		create quartier number: 1 {
			nom <- "Analakely";
			location <- {20.0, 22.0};
			shape <- rectangle(38.0, 40.0);
			couleur <- rgb(252, 243, 230);
		}
		create quartier number: 1 {
			nom <- "Isotry";
			location <- {78.0, 28.0};
			shape <- rectangle(40.0, 42.0);
			couleur <- rgb(232, 244, 250);
		}
		create quartier number: 1 {
			nom <- "Andraharo";
			location <- {52.0, 78.0};
			shape <- rectangle(44.0, 38.0);
			couleur <- rgb(235, 245, 235);
		}
		create quartier number: 1 {
			nom <- "Antaninarenina";
			location <- {40.0, 48.0};
			shape <- rectangle(36.0, 30.0);
			couleur <- rgb(245, 235, 245);
		}
		create quartier number: 1 {
			nom <- "Mahamasina";
			location <- {70.0, 68.0};
			shape <- rectangle(34.0, 32.0);
			couleur <- rgb(250, 240, 230);
		}
		create quartier number: 1 {
			nom <- "Ivandry";
			location <- {18.0, 72.0};
			shape <- rectangle(34.0, 34.0);
			couleur <- rgb(240, 248, 255);
		}
	}

	/* Point dans l'emprise de la carte (nx, ny entre 0 et 1) — toujours visible. */
	point coord_carte (float nx, float ny) {
		geometry e <- world.shape;
		float x <- e.location.x - (e.width / 2.0) + nx * e.width;
		float y <- e.location.y - (e.height / 2.0) + ny * e.height;
		return {x, y};
	}

	/* Applique les echelles d'affichage / reseau selon GIS. */
	action configurer_echelle_spatiale {
		if utiliser_gis {
			geometry e <- world.shape;
			float span <- max(e.width, e.height);
			taille_symbole <- span * 0.04;
			taille_icone <- span * 0.05;
			offset_label <- span * 0.045;
			seuil_distance_reseau <- span * 0.35;
			if vitesse_foyer > 0.01 {
				vitesse_foyer <- span * 0.004;
			}
		} else {
			taille_symbole <- 3.2;
			taille_icone <- 5.5;
			offset_label <- 4.8;
			seuil_distance_reseau <- 60.0;
		}
	}

	action creer_environnement {
		do configurer_echelle_spatiale;
		if !utiliser_gis {
			do creer_quartiers_abstraits;
		}
		do creer_magasins_et_salles;
	}

	action creer_magasins_et_salles {
		/* Positions relatives dans l'emprise carte (toujours visibles avec le fond OSM). */
		point p_shoprite;
		point p_isotry;
		point p_superu;
		point p_fitness;
		point p_dojo;
		point p_gym;
		if utiliser_gis {
			p_shoprite <- coord_carte(0.42, 0.48);
			p_isotry <- coord_carte(0.18, 0.62);
			p_superu <- coord_carte(0.55, 0.82);
			p_fitness <- coord_carte(0.35, 0.50);
			p_dojo <- coord_carte(0.48, 0.28);
			p_gym <- coord_carte(0.28, 0.78);
		} else {
			p_shoprite <- {20.0, 20.0};
			p_isotry <- {80.0, 30.0};
			p_superu <- {50.0, 80.0};
			p_fitness <- {40.0, 50.0};
			p_dojo <- {70.0, 70.0};
			p_gym <- {15.0, 75.0};
		}

		create magasin number: 1 {
			nom <- "Shoprite Analakely";
			label_carte <- "Shoprite";
			type_magasin <- "grande_surface";
			quartier_nom <- "Analakely";
			location <- p_shoprite;
			produits_disponibles <- ["riz", "huile", "tomate", "oignon", "poulet", "porc", "boeuf", "poisson",
				"lait_coco", "haricot", "carotte", "pain", "fromage", "oeuf", "pates", "tofu", "chips", "soda",
				"ananas", "avocat", "thon", "curry", "arachide", "sauce_soja", "legumes", "petit_pois",
				"mais", "lait", "sucre", "farine_riz", "farine"];
			prix <- ["riz"::2000.0, "huile"::3000.0, "tomate"::1000.0, "oignon"::800.0, "poulet"::6000.0,
				"porc"::5500.0, "boeuf"::7000.0, "poisson"::5000.0, "lait_coco"::2500.0, "haricot"::1500.0,
				"carotte"::1000.0, "pain"::1200.0, "fromage"::4000.0, "oeuf"::500.0, "pates"::2000.0,
				"tofu"::3500.0, "chips"::1500.0, "soda"::1000.0, "ananas"::1500.0, "avocat"::2000.0,
				"thon"::3500.0, "curry"::1800.0, "arachide"::1200.0, "sauce_soja"::1500.0,
				"legumes"::2000.0, "petit_pois"::1500.0, "mais"::1000.0, "lait"::2000.0,
				"sucre"::1500.0, "farine_riz"::1800.0, "farine"::1600.0];
		}
		create magasin number: 1 {
			nom <- "Epicerie Isotry";
			label_carte <- "Isotry";
			type_magasin <- "epicerie_locale";
			quartier_nom <- "Isotry";
			location <- p_isotry;
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
			quartier_nom <- "Andraharo";
			location <- p_superu;
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
			quartier_nom <- "Antaninarenina";
			location <- p_fitness;
		}
		create salle_de_sport number: 1 {
			nom <- "Dojo Mahamasina";
			label_carte <- "Dojo";
			quartier_nom <- "Mahamasina";
			location <- p_dojo;
		}
		create salle_de_sport number: 1 {
			nom <- "Gym Ivandry";
			label_carte <- "Gym";
			quartier_nom <- "Ivandry";
			location <- p_gym;
		}
	}

	action construire_reseau {
		list noeuds <- list(magasin) + list(salle_de_sport) + list(household);
		reseau_quartier <- as_distance_graph(noeuds, seuil_distance_reseau);
	}

	action creer_personas {
		int n <- min(nb_households, 8);
		loop i from: 0 to: n - 1 {
			create household number: 1 {
				if i = 0 {
					if utiliser_gis {
						location <- world.coord_carte(0.38, 0.52);
					} else {
						location <- {25.0, 45.0};
					}
					nom_foyer <- "Foyer Malgache";
					label_carte <- "Malgache";
					quartier_nom <- "Antaninarenina";
					storage_mode <- "etalage";
					nb_personnes <- 5;
					budget_periode <- 35000.0;
					salaire <- 35000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("limite");
				} else if i = 1 {
					if utiliser_gis {
						location <- world.coord_carte(0.45, 0.42);
					} else {
						location <- {55.0, 25.0};
					}
					nom_foyer <- "Foyer Europeen";
					label_carte <- "Europeen";
					quartier_nom <- "Analakely";
					storage_mode <- "frigidaire";
					nb_personnes <- 1;
					budget_periode <- 80000.0;
					salaire <- 80000.0;
					restrictions_culturelles <- [];
					allergies <- ["fruits_de_mer"];
					regime <- "equilibre";
					do initialiser_provisions("moyen");
				} else if i = 2 {
					if utiliser_gis {
						location <- world.coord_carte(0.22, 0.58);
					} else {
						location <- {75.0, 55.0};
					}
					nom_foyer <- "Foyer Sans Porc";
					label_carte <- "Sans porc";
					quartier_nom <- "Isotry";
					storage_mode <- "panier";
					nb_personnes <- 3;
					budget_periode <- 50000.0;
					salaire <- 50000.0;
					restrictions_culturelles <- ["pas_de_porc"];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("faible");
				} else if i = 3 {
					if utiliser_gis {
						location <- world.coord_carte(0.32, 0.75);
					} else {
						location <- {35.0, 75.0};
					}
					nom_foyer <- "Foyer Vegan";
					label_carte <- "Vegan";
					quartier_nom <- "Ivandry";
					storage_mode <- "frigidaire";
					nb_personnes <- 2;
					budget_periode <- 30000.0;
					salaire <- 30000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "vegan";
					do initialiser_provisions("riche");
				} else if i = 4 {
					if utiliser_gis {
						location <- world.coord_carte(0.50, 0.32);
					} else {
						location <- {60.0, 60.0};
					}
					nom_foyer <- "Foyer Defaut";
					label_carte <- "Defaut";
					quartier_nom <- "Mahamasina";
					storage_mode <- "etalage";
					nb_personnes <- 2;
					budget_periode <- budget_initial_defaut;
					salaire <- budget_initial_defaut;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("moyen");
				} else if i = 5 {
					if utiliser_gis {
						location <- world.coord_carte(0.15, 0.55);
					} else {
						location <- {85.0, 40.0};
					}
					nom_foyer <- "Foyer Malbouffe";
					label_carte <- "Malbouffe";
					quartier_nom <- "Isotry";
					storage_mode <- "etalage";
					nb_personnes <- 1;
					budget_periode <- 60000.0;
					salaire <- 60000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "malbouffe_assumee";
					do initialiser_provisions("moyen");
				} else if i = 6 {
					if utiliser_gis {
						location <- world.coord_carte(0.60, 0.55);
					} else {
						location <- {45.0, 35.0};
					}
					nom_foyer <- "Foyer Etudiant";
					label_carte <- "Etudiant";
					quartier_nom <- "Analakely";
					storage_mode <- "panier";
					nb_personnes <- 1;
					budget_periode <- 20000.0;
					salaire <- 20000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "aucun";
					do initialiser_provisions("faible");
				} else {
					if utiliser_gis {
						location <- world.coord_carte(0.40, 0.70);
					} else {
						location <- {30.0, 80.0};
					}
					nom_foyer <- "Foyer Sportif";
					label_carte <- "Sportif";
					quartier_nom <- "Ivandry";
					storage_mode <- "frigidaire";
					nb_personnes <- 2;
					budget_periode <- 55000.0;
					salaire <- 55000.0;
					restrictions_culturelles <- [];
					allergies <- [];
					regime <- "equilibre";
					do initialiser_provisions("riche");
				}
				budget_restant <- salaire;
				do creer_agents_decision;
			}
		}
	}
}
