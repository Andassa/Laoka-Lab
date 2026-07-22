/**
 * Entites de donnees et agents spatiaux (aucune dependance).
 */
model Entites

species plat_item {
	string nom_plat <- "";
	list ingredients <- [];
	float cout_estime <- 0.0;
	string categorie_nutritionnelle <- "equilibre";
	bool contient_porc <- false;
	list allergenes <- [];
	bool est_vegan <- false;
}

species ingredient_stock {
	string nom <- "";
	float quantite <- 0.0;
	string unite <- "unite";
	string categorie <- "autre";
	string provenance <- "etalage";
	int date_peremption <- -1;
	agent foyer_proprietaire;
}

species magasin {
	string nom <- "";
	string label_carte <- "";
	string type_magasin <- "epicerie_locale";
	list produits_disponibles <- [];
	map prix <- [];
	image_file icone <- image_file("../includes/icons/magasin.png");

	aspect base {
		draw circle(3.2) color: #orange border: #black;
		draw icone size: 5.5;
		draw label_carte color: #black size: 10 at: location + {0.0, 4.8};
	}
}

species salle_de_sport {
	string nom <- "";
	string label_carte <- "";
	image_file icone <- image_file("../includes/icons/salle_sport.png");

	aspect base {
		draw circle(3.2) color: #lightgreen border: #darkgreen;
		draw icone size: 5.5;
		draw label_carte color: #darkgreen size: 10 at: location + {0.0, 4.8};
	}
}
