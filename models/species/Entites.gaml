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
	string type_magasin <- "epicerie_locale";
	list produits_disponibles <- [];
	map prix <- [];
	image_file icone <- image_file("../includes/icons/magasin.png");

	aspect base {
		draw icone size: 9.0;
		draw nom color: #black size: 8 at: location + {0.0, -7.0};
	}
}

species salle_de_sport {
	string nom <- "";
	image_file icone <- image_file("../includes/icons/salle_sport.png");

	aspect base {
		draw icone size: 9.0;
		draw nom color: #darkgreen size: 8 at: location + {0.0, -7.0};
	}
}
