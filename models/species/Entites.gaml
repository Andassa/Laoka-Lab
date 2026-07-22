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

	aspect base {
		draw square(4.0) color: #orange border: #black;
		draw nom color: #black size: 8 at: location + {0.0, -5.0};
	}
}

species salle_de_sport {
	string nom <- "";

	aspect base {
		draw triangle(4.0) color: #green border: #black;
		draw nom color: #darkgreen size: 8 at: location + {0.0, -5.0};
	}
}
