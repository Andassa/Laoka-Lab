/**
 * Initialisation du monde : catalogue, magasins, salles, personas, reseau.
 */
model InitMonde

import "../species/Agents.gaml"

global {
	list catalogue_plats <- [];
	graph reseau_quartier;
	int nb_households <- 8;
	float budget_initial_defaut <- 50000.0;
	bool utiliser_gis <- true;

	list split_non_vide (string raw, string sep) {
		list out <- [];
		if raw = nil or raw = "" or raw = "nil" {
			return out;
		}
		list parts <- raw split_with sep;
		loop p over: parts {
			if p != nil and p != "" {
				out <- out + [p];
			}
		}
		return out;
	}

	action charger_plats {
		file f <- csv_file("../includes/plats.csv", true);
		matrix mat <- matrix(f);
		loop lig from: 0 to: mat.rows - 1 {
			create plat_item number: 1 returns: nouveaux {
				nom_plat <- "" + mat[0, lig];
				ingredients <- world.split_non_vide("" + mat[1, lig], ";");
				cout_estime <- float(mat[2, lig]);
				categorie_nutritionnelle <- "" + mat[3, lig];
				contient_porc <- (lower_case("" + mat[4, lig]) = "true");
				allergenes <- world.split_non_vide("" + mat[5, lig], ";");
				est_vegan <- (lower_case("" + mat[6, lig]) = "true");
			}
			catalogue_plats <- catalogue_plats + nouveaux;
		}
		write "Catalogue charge : " + length(catalogue_plats) + " plats";
	}

	point pos_carte (float nx, float ny, point fallback) {
		if utiliser_gis {
			return coord_carte(nx, ny);
		}
		return fallback;
	}

	/* Fond pedagogique abstrait (si GIS OFF). */
	action creer_quartiers_abstraits {
		create quartier number: 1 {
			nom <- "Analakely"; location <- {20.0, 22.0}; shape <- rectangle(38.0, 40.0); couleur <- rgb(252, 243, 230);
		}
		create quartier number: 1 {
			nom <- "Isotry"; location <- {78.0, 28.0}; shape <- rectangle(40.0, 42.0); couleur <- rgb(232, 244, 250);
		}
		create quartier number: 1 {
			nom <- "Andraharo"; location <- {52.0, 78.0}; shape <- rectangle(44.0, 38.0); couleur <- rgb(235, 245, 235);
		}
		create quartier number: 1 {
			nom <- "Antaninarenina"; location <- {40.0, 48.0}; shape <- rectangle(36.0, 30.0); couleur <- rgb(245, 235, 245);
		}
		create quartier number: 1 {
			nom <- "Mahamasina"; location <- {70.0, 68.0}; shape <- rectangle(34.0, 32.0); couleur <- rgb(250, 240, 230);
		}
		create quartier number: 1 {
			nom <- "Ivandry"; location <- {18.0, 72.0}; shape <- rectangle(34.0, 34.0); couleur <- rgb(240, 248, 255);
		}
	}

	point coord_carte (float nx, float ny) {
		geometry e <- world.shape;
		float x <- e.location.x - (e.width / 2.0) + nx * e.width;
		float y <- e.location.y - (e.height / 2.0) + ny * e.height;
		return {x, y};
	}

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
		point p_shoprite <- pos_carte(0.42, 0.48, {20.0, 20.0});
		point p_isotry <- pos_carte(0.18, 0.62, {80.0, 30.0});
		point p_superu <- pos_carte(0.55, 0.82, {50.0, 80.0});
		point p_fitness <- pos_carte(0.35, 0.50, {40.0, 50.0});
		point p_dojo <- pos_carte(0.48, 0.28, {70.0, 70.0});
		point p_gym <- pos_carte(0.28, 0.78, {15.0, 75.0});

		create magasin number: 1 {
			nom <- "Shoprite Analakely"; label_carte <- "Shoprite"; type_magasin <- "grande_surface";
			quartier_nom <- "Analakely"; location <- p_shoprite;
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
			nom <- "Epicerie Isotry"; label_carte <- "Isotry"; type_magasin <- "epicerie_locale";
			quartier_nom <- "Isotry"; location <- p_isotry;
			produits_disponibles <- ["riz", "huile", "tomate", "oignon", "brede", "feuilles_manioc", "haricot",
				"banane", "mangue", "lait", "sucre", "farine_riz"];
			prix <- ["riz"::1800.0, "huile"::2800.0, "tomate"::900.0, "oignon"::700.0, "brede"::500.0,
				"feuilles_manioc"::600.0, "haricot"::1400.0, "banane"::800.0, "mangue"::1000.0,
				"lait"::2000.0, "sucre"::1500.0, "farine_riz"::1800.0];
		}
		create magasin number: 1 {
			nom <- "SuperU Andraharo"; label_carte <- "SuperU"; type_magasin <- "grande_surface";
			quartier_nom <- "Andraharo"; location <- p_superu;
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
			nom <- "Fitness Park Antaninarenina"; label_carte <- "Fitness";
			quartier_nom <- "Antaninarenina"; location <- p_fitness;
		}
		create salle_de_sport number: 1 {
			nom <- "Dojo Mahamasina"; label_carte <- "Dojo";
			quartier_nom <- "Mahamasina"; location <- p_dojo;
		}
		create salle_de_sport number: 1 {
			nom <- "Gym Ivandry"; label_carte <- "Gym";
			quartier_nom <- "Ivandry"; location <- p_gym;
		}
	}

	action construire_reseau {
		reseau_quartier <- as_distance_graph(list(magasin) + list(salle_de_sport) + list(household), seuil_distance_reseau);
	}

	/* Factory foyer : evite la duplication des 8 blocs create. */
	action creer_foyer (point loc, string nom, string label, string qnom, string storage,
			int npers, float sal, list restr, list alls, string reg, string stock_niv) {
		create household number: 1 {
			location <- loc;
			nom_foyer <- nom;
			label_carte <- label;
			quartier_nom <- qnom;
			storage_mode <- storage;
			nb_personnes <- npers;
			salaire <- sal;
			budget_periode <- sal;
			budget_restant <- sal;
			restrictions_culturelles <- restr;
			allergies <- alls;
			regime <- reg;
			do initialiser_provisions(stock_niv);
			do creer_agents_decision;
		}
	}

	action creer_personas {
		int n <- min(nb_households, 8);
		if n > 0 {
			do creer_foyer(pos_carte(0.38, 0.52, {25.0, 45.0}), "Foyer Malgache", "Malgache", "Antaninarenina",
				"etalage", 5, 35000.0, [], [], "aucun", "limite");
		}
		if n > 1 {
			do creer_foyer(pos_carte(0.45, 0.42, {55.0, 25.0}), "Foyer Europeen", "Europeen", "Analakely",
				"frigidaire", 1, 80000.0, [], ["fruits_de_mer"], "equilibre", "moyen");
		}
		if n > 2 {
			do creer_foyer(pos_carte(0.22, 0.58, {75.0, 55.0}), "Foyer Sans Porc", "Sans porc", "Isotry",
				"panier", 3, 50000.0, ["pas_de_porc"], [], "aucun", "faible");
		}
		if n > 3 {
			do creer_foyer(pos_carte(0.32, 0.75, {35.0, 75.0}), "Foyer Vegan", "Vegan", "Ivandry",
				"frigidaire", 2, 30000.0, [], [], "vegan", "riche");
		}
		if n > 4 {
			do creer_foyer(pos_carte(0.50, 0.32, {60.0, 60.0}), "Foyer Defaut", "Defaut", "Mahamasina",
				"etalage", 2, budget_initial_defaut, [], [], "aucun", "moyen");
		}
		if n > 5 {
			do creer_foyer(pos_carte(0.15, 0.55, {85.0, 40.0}), "Foyer Malbouffe", "Malbouffe", "Isotry",
				"etalage", 1, 60000.0, [], [], "malbouffe_assumee", "moyen");
		}
		if n > 6 {
			do creer_foyer(pos_carte(0.60, 0.55, {45.0, 35.0}), "Foyer Etudiant", "Etudiant", "Analakely",
				"panier", 1, 20000.0, [], [], "aucun", "faible");
		}
		if n > 7 {
			do creer_foyer(pos_carte(0.40, 0.70, {30.0, 80.0}), "Foyer Sportif", "Sportif", "Ivandry",
				"frigidaire", 2, 55000.0, [], [], "equilibre", "riche");
		}
	}
}
