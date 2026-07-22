/**
 * Entites de donnees et agents spatiaux (aucune dependance).
 */
model Entites

/* Variables d'affichage (fusionnees avec le modele principal). */
global {
	bool utiliser_gis <- true;
	bool afficher_icones <- true;
	float taille_symbole <- 3.2;
	float taille_icone <- 5.5;
	float offset_label <- 4.8;
	float seuil_distance_reseau <- 60.0;
}

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

/* Routes OSM (importees depuis shapefile). */
species route {
	int osm_id <- 0;
	string name <- "";
	string highway <- "";
	string fclass <- "";

	aspect base {
		rgb c <- rgb(200, 200, 200);
		if highway = "primary" or highway = "trunk" or highway = "motorway" {
			c <- rgb(120, 120, 120);
		} else if highway = "secondary" {
			c <- rgb(150, 150, 150);
		} else if highway = "tertiary" {
			c <- rgb(170, 170, 170);
		}
		draw shape color: c;
	}
}

/* Quartiers stylises (mode abstrait uniquement). */
species quartier {
	string nom <- "";
	rgb couleur <- #white;

	aspect base {
		draw shape color: couleur border: #darkgray;
		draw nom color: #dimgray size: 11 at: location;
	}
}

species magasin {
	string nom <- "";
	string label_carte <- "";
	string type_magasin <- "epicerie_locale";
	string quartier_nom <- "";
	list produits_disponibles <- [];
	map prix <- [];
	image_file icone <- image_file("../includes/icons/magasin.png");

	aspect base {
		/* Cercles colores toujours dessines (visibles meme en GIS). */
		draw circle(taille_symbole) color: #orange border: #black;
		if afficher_icones and !utiliser_gis {
			draw icone size: taille_icone;
		}
		draw label_carte color: #black size: 12 at: location + {0.0, offset_label};
	}
}

species salle_de_sport {
	string nom <- "";
	string label_carte <- "";
	string quartier_nom <- "";
	image_file icone <- image_file("../includes/icons/salle_sport.png");

	aspect base {
		draw circle(taille_symbole) color: #lightgreen border: #darkgreen;
		if afficher_icones and !utiliser_gis {
			draw icone size: taille_icone;
		}
		draw label_carte color: #darkgreen size: 12 at: location + {0.0, offset_label};
	}
}
