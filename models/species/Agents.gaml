/**
 * Foyers + pipeline d'agents de decision.
 * Depend de Entites.gaml (plat_item, magasin, salle_de_sport, ingredient_stock).
 */
model Agents

import "Entites.gaml"

/* Variables / helpers monde (fusionnes avec LaokaLab ; redefinis dans le modele principal). */
global {
	float tolerance_depassement_budget <- 0.10;
	int seuil_alerte_nutrition <- 5;
	int nb_alertes_nutritionnelles_total <- 0;
	int nb_alertes_ce_cycle <- 0;
	int nb_repetitions_evitees <- 0;
	int nb_recours_magasin <- 0;
	int nb_unites_achetees_total <- 0;
	float stock_moyen_foyers <- 0.0;
	float budget_moyen_restant <- 0.0;
	float qte_achat_pack <- 4.0;
	int pas_entre_plans <- 20;
	float vitesse_foyer <- 2.0;
	bool activer_deplacement <- false;
	bool afficher_icones <- true;
	int nb_plans_max <- 40;
	int nb_plans_faits <- 0;
	bool simulation_terminee <- false;
	/* reset = ancien comportement ; revenu = report + allocation periode ; persist = jamais recharge */
	string mode_budget <- "revenu";
	bool utiliser_negociation_scores <- true;
	float poids_budget <- 1.0;
	float poids_nutrition <- 1.0;
	float poids_stock <- 1.2;
	float poids_historique <- 0.8;
	/* Metriques de conflit (cumul du plan courant). */
	int rejets_culture_plan <- 0;
	int rejets_budget_plan <- 0;
	int evitements_hist_plan <- 0;
	int repas_malbouffe_plan <- 0;
	int repas_equilibre_plan <- 0;
	float pct_malbouffe <- 0.0;
	float pct_rejet_culture <- 0.0;
	float pct_rejet_budget <- 0.0;
	graph reseau_quartier;
	list catalogue_plats <- [];

	int calculer_nb_repas {
		return 21;
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
}

/* ========== Parent commun ========== */
species agent_decision {
	household mon_foyer;

	bool liste_contient (list xs, string v) {
		loop x over: xs {
			if x = v {
				return true;
			}
		}
		return false;
	}

	list trier_plats_par_cout (list candidats) {
		list triee <- [];
		list reste <- list(candidats);
		loop while: length(reste) > 0 {
			plat_item meilleur <- reste[0] as plat_item;
			int idx_m <- 0;
			int i <- 0;
			loop p over: reste {
				plat_item pi <- p as plat_item;
				if pi.cout_estime < meilleur.cout_estime {
					meilleur <- pi;
					idx_m <- i;
				}
				i <- i + 1;
			}
			triee <- triee + [meilleur];
			list nouveau_reste <- [];
			int j <- 0;
			loop p over: reste {
				if j != idx_m {
					nouveau_reste <- nouveau_reste + [p];
				}
				j <- j + 1;
			}
			reste <- nouveau_reste;
		}
		return triee;
	}
}

/* ========== Filtres ========== */
species agent_provisions parent: agent_decision {

	list evaluer_candidats (list candidats) {
		list resultats <- [];
		loop p over: candidats {
			plat_item pi <- p as plat_item;
			list manques <- [];
			loop ing over: pi.ingredients {
				if quantite_dispo(ing) < 1.0 {
					manques <- manques + [ing];
				}
			}
			resultats <- resultats + [[
				"plat"::pi,
				"manques"::manques,
				"faisable"::(length(manques) = 0),
				"nb_manques"::length(manques)
			]];
		}
		return resultats;
	}

	float quantite_dispo (string nom_ing) {
		loop s over: mon_foyer.provisions {
			ingredient_stock st <- s as ingredient_stock;
			if st.nom = nom_ing {
				return st.quantite;
			}
		}
		return 0.0;
	}

	action ajouter_ingredient (string nom_ing, float qte) {
		bool trouve <- false;
		loop s over: mon_foyer.provisions {
			ingredient_stock st <- s as ingredient_stock;
			if st.nom = nom_ing {
				st.quantite <- st.quantite + qte;
				trouve <- true;
			}
		}
		if !trouve {
			create ingredient_stock number: 1 returns: stocks {
				nom <- nom_ing;
				quantite <- qte;
				provenance <- myself.mon_foyer.storage_mode;
				foyer_proprietaire <- myself.mon_foyer;
			}
			mon_foyer.provisions <- mon_foyer.provisions + stocks;
		}
	}

	/* Achat : reconstitue un pack pour chaque ingredient manquant. */
	action acheter_ingredients (list manques, float qte_pack) {
		loop ing over: manques {
			do ajouter_ingredient(ing, qte_pack);
			nb_unites_achetees_total <- nb_unites_achetees_total + 1;
		}
	}

	/* Consommation : 1 unite d'ingredient par repas (le cout budget reste x personnes). */
	action consommer_ingredients (list ingredients, int portions) {
		loop ing over: ingredients {
			loop s over: mon_foyer.provisions {
				ingredient_stock st <- s as ingredient_stock;
				if st.nom = ing {
					st.quantite <- st.quantite - 1.0;
					if st.quantite < 0.0 {
						st.quantite <- 0.0;
					}
				}
			}
		}
	}

	float stock_total {
		float total <- 0.0;
		loop s over: mon_foyer.provisions {
			total <- total + (s as ingredient_stock).quantite;
		}
		return total;
	}
}

species agent_budget parent: agent_decision {

	list filtrer_budget (list candidats, float budget_dispo, int personnes) {
		list ok <- [];
		loop p over: candidats {
			plat_item pi <- p as plat_item;
			if pi.cout_estime * personnes <= budget_dispo {
				ok <- ok + [pi];
			}
		}
		if length(ok) = 0 {
			float plafond_souple <- budget_dispo * (1.0 + tolerance_depassement_budget);
			loop p over: candidats {
				plat_item pi <- p as plat_item;
				if pi.cout_estime * personnes <= plafond_souple {
					ok <- ok + [pi];
				}
			}
		}
		/* Dernier recours : le moins cher (evite ECHEC_ARBITRAGE systematique en fin de periode). */
		if length(ok) = 0 and length(candidats) > 0 {
			return trier_plats_par_cout(candidats);
		}
		return trier_plats_par_cout(ok);
	}
}

species agent_culture_restriction parent: agent_decision {

	list filtrer_strict (list candidats) {
		list ok <- list(candidats);
		if liste_contient(mon_foyer.restrictions_culturelles, "pas_de_porc") {
			list tmp <- [];
			loop p over: ok {
				plat_item pi <- p as plat_item;
				if !pi.contient_porc {
					tmp <- tmp + [pi];
				}
			}
			ok <- tmp;
		}
		if mon_foyer.regime = "vegan" {
			list tmp2 <- [];
			loop p over: ok {
				plat_item pi <- p as plat_item;
				if pi.est_vegan {
					tmp2 <- tmp2 + [pi];
				}
			}
			ok <- tmp2;
		}
		loop all over: mon_foyer.allergies {
			list tmp3 <- [];
			loop p over: ok {
				plat_item pi <- p as plat_item;
				if !liste_contient(pi.allergenes, all) {
					tmp3 <- tmp3 + [pi];
				}
			}
			ok <- tmp3;
		}
		return ok;
	}
}

species agent_nutrition parent: agent_decision {
	int compteur_malbouffe_periode <- 0;

	list orienter (list candidats) {
		if mon_foyer.regime = "malbouffe_assumee" {
			list junk <- [];
			loop p over: candidats {
				plat_item pi <- p as plat_item;
				if pi.categorie_nutritionnelle = "malbouffe" {
					junk <- junk + [pi];
				}
			}
			if length(junk) > 0 {
				return junk;
			}
			return candidats;
		}
		list eq <- [];
		loop p over: candidats {
			plat_item pi <- p as plat_item;
			if pi.categorie_nutritionnelle = "equilibre" {
				eq <- eq + [pi];
			}
		}
		if length(eq) > 0 {
			return eq;
		}
		return candidats;
	}

	action enregistrer_choix (plat_item p) {
		if p.categorie_nutritionnelle = "malbouffe" {
			compteur_malbouffe_periode <- compteur_malbouffe_periode + 1;
		}
	}

	bool verifier_alerte {
		if compteur_malbouffe_periode >= seuil_alerte_nutrition {
			mon_foyer.alertes_nutritionnelles <- mon_foyer.alertes_nutritionnelles + 1;
			nb_alertes_nutritionnelles_total <- nb_alertes_nutritionnelles_total + 1;
			ask mon_foyer.mon_logistique {
				do trouver_salle_sport;
			}
			return true;
		}
		return false;
	}

	action reset_compteur {
		compteur_malbouffe_periode <- 0;
	}
}

species agent_historique parent: agent_decision {

	list eviter_repetitions (list candidats) {
		list interdits <- [];
		loop r over: mon_foyer.historique_repas {
			map rm <- map(r);
			interdits <- interdits + [string(rm["nom_plat"])];
		}
		loop r over: mon_foyer.plan_courant {
			map rm <- map(r);
			interdits <- interdits + [string(rm["nom_plat"])];
		}
		list sans_rep <- [];
		loop p over: candidats {
			plat_item pi <- p as plat_item;
			if !liste_contient(interdits, pi.nom_plat) {
				sans_rep <- sans_rep + [pi];
			}
		}
		if length(sans_rep) = 0 {
			return candidats;
		}
		if length(candidats) > length(sans_rep) {
			nb_repetitions_evitees <- nb_repetitions_evitees + 1;
		}
		return sans_rep;
	}
}

/* ========== Logistique ========== */
species agent_logistique parent: agent_decision {

	map trouver_magasin_pour (list ingredients_manquants) {
		if length(ingredients_manquants) = 0 {
			return ["magasin"::"", "distance"::0.0, "chemin_longueur"::0.0];
		}
		magasin meilleur <- nil;
		float meilleure_path <- 999999.0;
		int meilleur_couverture <- -1;

		ask magasin {
			int couverture <- 0;
			loop ing over: ingredients_manquants {
				if myself.liste_contient(produits_disponibles, ing) {
					couverture <- couverture + 1;
				}
			}
			float plen <- myself.mon_foyer distance_to self;
			if reseau_quartier != nil {
				path chemin <- path_between(reseau_quartier, myself.mon_foyer.location, self.location);
				if chemin != nil {
					plen <- chemin.shape.perimeter;
				}
			}
			if (couverture > meilleur_couverture) or (couverture = meilleur_couverture and plen < meilleure_path) {
				meilleur_couverture <- couverture;
				meilleure_path <- plen;
				meilleur <- self;
			}
		}

		if meilleur != nil {
			nb_recours_magasin <- nb_recours_magasin + 1;
			mon_foyer.magasin_cible <- meilleur;
			return [
				"magasin"::meilleur.nom,
				"distance"::meilleure_path,
				"chemin_longueur"::meilleure_path,
				"couverture"::meilleur_couverture
			];
		}
		return ["magasin"::"aucun", "distance"::0.0, "chemin_longueur"::0.0];
	}

	action trouver_salle_sport {
		salle_de_sport s <- salle_de_sport closest_to mon_foyer;
		if s != nil {
			float plen <- mon_foyer distance_to s;
			if reseau_quartier != nil {
				path chemin <- path_between(reseau_quartier, mon_foyer.location, s.location);
				if chemin != nil {
					plen <- chemin.shape.perimeter;
				}
			}
			mon_foyer.salle_cible <- s;
			mon_foyer.derniere_salle_sport <- s.nom + " (d=" + int(plen) + ")";
		}
	}
}

/* ========== Arbitrage ========== */
species agent_arbitrage parent: agent_decision {

	action generer_plan_periode {
		mon_foyer.plan_courant <- [];
		mon_foyer.nb_repas_depuis_stock <- 0;
		mon_foyer.nb_repas_avec_achat <- 0;
		ask mon_foyer.mon_nutrition {
			do reset_compteur;
		}
		int n <- world.calculer_nb_repas();
		loop i from: 0 to: n - 1 {
			string type_r <- world.calculer_type_repas(i);
			int repas_restants <- n - i;
			float enveloppe <- mon_foyer.budget_restant / repas_restants;
			map repas_genere <- selectionner_un_repas(type_r, enveloppe);
			mon_foyer.plan_courant <- mon_foyer.plan_courant + [repas_genere];
			if bool(repas_genere["achat_necessaire"]) {
				mon_foyer.necessite_achat <- true;
				mon_foyer.nb_repas_avec_achat <- mon_foyer.nb_repas_avec_achat + 1;
			} else {
				mon_foyer.nb_repas_depuis_stock <- mon_foyer.nb_repas_depuis_stock + 1;
			}
			mon_foyer.budget_restant <- mon_foyer.budget_restant - float(repas_genere["cout"]);
			if mon_foyer.budget_restant < 0.0 {
				mon_foyer.budget_restant <- 0.0;
			}
		}
		ask mon_foyer.mon_nutrition {
			if verifier_alerte() {
				nb_alertes_ce_cycle <- nb_alertes_ce_cycle + 1;
				if length(myself.mon_foyer.plan_courant) > 0 {
					int idx <- length(myself.mon_foyer.plan_courant) - 1;
					map dernier <- map(myself.mon_foyer.plan_courant[idx]);
					string j <- string(dernier["justification"]);
					map annote <- [
						"type_repas"::dernier["type_repas"],
						"nom_plat"::dernier["nom_plat"],
						"cout"::dernier["cout"],
						"ingredients_utilises"::dernier["ingredients_utilises"],
						"ingredients_a_acheter"::dernier["ingredients_a_acheter"],
						"magasin_suggere"::dernier["magasin_suggere"],
						"salle_sport_suggeree"::myself.mon_foyer.derniere_salle_sport,
						"justification"::(j + " | ALERTE nutrition + salle: " + myself.mon_foyer.derniere_salle_sport),
						"categorie_nutritionnelle"::dernier["categorie_nutritionnelle"],
						"achat_necessaire"::dernier["achat_necessaire"]
					];
					myself.mon_foyer.plan_courant[idx] <- annote;
				}
			}
		}
	}

	map selectionner_un_repas (string type_r, float enveloppe_budget) {
		list candidats <- list(catalogue_plats);
		string justifs <- "";
		int n_cat <- length(candidats);

		/* Contrainte DURE : culture / allergies. */
		list apres_culture <- mon_foyer.mon_culture.filtrer_strict(candidats);
		justifs <- justifs + "culture:" + length(apres_culture) + "/" + n_cat;
		rejets_culture_plan <- rejets_culture_plan + (n_cat - length(apres_culture));
		if length(apres_culture) = 0 {
			return repas_echec(type_r, "Aucun plat compatible culture/allergies");
		}

		float plafond <- enveloppe_budget;
		if plafond < 1.0 {
			plafond <- 1.0;
		}
		int hors_budget <- 0;
		loop p over: apres_culture {
			plat_item pi <- p as plat_item;
			if pi.cout_estime * mon_foyer.nb_personnes > plafond {
				hors_budget <- hors_budget + 1;
			}
		}
		rejets_budget_plan <- rejets_budget_plan + hors_budget;

		list interdits <- [];
		loop r over: mon_foyer.historique_repas {
			map rm <- map(r);
			interdits <- interdits + [string(rm["nom_plat"])];
		}
		loop r over: mon_foyer.plan_courant {
			map rm <- map(r);
			interdits <- interdits + [string(rm["nom_plat"])];
		}

		plat_item choisi;
		string justification_finale <- "";
		bool achat <- false;
		list manques <- [];
		string magasin_nom <- "";

		if utiliser_negociation_scores {
			float meilleur_score <- -999999.0;
			plat_item meilleur_plat;
			bool premier <- true;
			loop p over: apres_culture {
				plat_item pi <- p as plat_item;
				float sc <- score_negociation(pi, plafond, interdits);
				if premier or sc > meilleur_score {
					meilleur_score <- sc;
					meilleur_plat <- pi;
					premier <- false;
				}
			}
			choisi <- meilleur_plat;
			justifs <- justifs + " > scores:" + int(meilleur_score);
			list eval_un <- mon_foyer.mon_provisions.evaluer_candidats([choisi]);
			map em <- map(eval_un[0]);
			manques <- list(em["manques"]);
			achat <- !bool(em["faisable"]);
			if achat {
				map info_mag <- mon_foyer.mon_logistique.trouver_magasin_pour(manques);
				magasin_nom <- string(info_mag["magasin"]);
				justification_finale <- "Score " + int(meilleur_score) + " | achat ("
					+ world.concat_liste(manques, ",") + ") @ " + magasin_nom + " | " + justifs;
			} else {
				justification_finale <- "Score " + int(meilleur_score) + " | stock OK | " + justifs;
			}
		} else {
			list apres_budget <- mon_foyer.mon_budget.filtrer_budget(
				apres_culture, plafond, mon_foyer.nb_personnes
			);
			justifs <- justifs + " > budget:" + length(apres_budget);
			if length(apres_budget) = 0 {
				return repas_echec(type_r, "Budget insuffisant meme avec tolerance");
			}
			list apres_hist <- mon_foyer.mon_historique.eviter_repetitions(apres_budget);
			justifs <- justifs + " > historique:" + length(apres_hist);
			if length(apres_hist) < length(apres_budget) {
				evitements_hist_plan <- evitements_hist_plan + (length(apres_budget) - length(apres_hist));
			}
			list apres_nutri <- mon_foyer.mon_nutrition.orienter(apres_hist);
			if length(apres_nutri) = 0 {
				apres_nutri <- apres_hist;
			}
			if length(apres_nutri) = 0 {
				apres_nutri <- apres_budget;
			}
			list eval_prov <- mon_foyer.mon_provisions.evaluer_candidats(apres_nutri);
			if length(eval_prov) = 0 {
				return repas_echec(type_r, "Aucun candidat apres filtres");
			}
			list faisables <- [];
			loop e over: eval_prov {
				map em2 <- map(e);
				if bool(em2["faisable"]) {
					faisables <- faisables + [em2];
				}
			}
			map choix_eval;
			if length(faisables) > 0 {
				faisables <- trier_evals_par_cout(faisables);
				choix_eval <- map(faisables[0]);
				justification_finale <- "Pipeline | stock OK | " + justifs;
			} else {
				eval_prov <- trier_evals_par_manques(eval_prov);
				choix_eval <- map(eval_prov[0]);
				manques <- list(choix_eval["manques"]);
				achat <- true;
				map info_mag2 <- mon_foyer.mon_logistique.trouver_magasin_pour(manques);
				magasin_nom <- string(info_mag2["magasin"]);
				justification_finale <- "Pipeline | achat (" + world.concat_liste(manques, ",")
					+ ") @ " + magasin_nom + " | " + justifs;
			}
			choisi <- choix_eval["plat"] as plat_item;
		}

		if choisi.categorie_nutritionnelle = "malbouffe" {
			repas_malbouffe_plan <- repas_malbouffe_plan + 1;
		} else {
			repas_equilibre_plan <- repas_equilibre_plan + 1;
		}
		if achat {
			ask mon_foyer.mon_provisions {
				do acheter_ingredients(manques, qte_achat_pack);
			}
		}
		ask mon_foyer.mon_provisions {
			do consommer_ingredients(choisi.ingredients, mon_foyer.nb_personnes);
		}
		ask mon_foyer.mon_nutrition {
			do enregistrer_choix(choisi);
		}
		float cout_total <- choisi.cout_estime * mon_foyer.nb_personnes;
		return [
			"type_repas"::type_r,
			"nom_plat"::choisi.nom_plat,
			"cout"::cout_total,
			"ingredients_utilises"::choisi.ingredients,
			"ingredients_a_acheter"::manques,
			"magasin_suggere"::magasin_nom,
			"salle_sport_suggeree"::"",
			"justification"::justification_finale,
			"categorie_nutritionnelle"::choisi.categorie_nutritionnelle,
			"achat_necessaire"::achat
		];
	}

	float score_negociation (plat_item pi, float enveloppe, list interdits) {
		float s <- 0.0;
		float cout <- pi.cout_estime * mon_foyer.nb_personnes;
		float plafond_souple <- enveloppe * (1.0 + tolerance_depassement_budget);
		if cout <= enveloppe {
			s <- s + poids_budget * (1.0 - (cout / (enveloppe + 1.0)));
		} else if cout <= plafond_souple {
			s <- s + poids_budget * 0.15;
		} else {
			s <- s - poids_budget * 1.5;
		}
		if liste_contient(interdits, pi.nom_plat) {
			s <- s - poids_historique;
			evitements_hist_plan <- evitements_hist_plan + 1;
		} else {
			s <- s + poids_historique * 0.4;
		}
		if mon_foyer.regime = "malbouffe_assumee" {
			if pi.categorie_nutritionnelle = "malbouffe" {
				s <- s + poids_nutrition;
			} else {
				s <- s + poids_nutrition * 0.25;
			}
		} else {
			if pi.categorie_nutritionnelle = "equilibre" {
				s <- s + poids_nutrition;
			} else {
				s <- s - poids_nutrition * 0.6;
			}
		}
		int nb_manques <- 0;
		loop ing over: pi.ingredients {
			if mon_foyer.mon_provisions.quantite_dispo(ing) < 1.0 {
				nb_manques <- nb_manques + 1;
			}
		}
		if nb_manques = 0 {
			s <- s + poids_stock;
		} else {
			s <- s - poids_stock * (0.25 * nb_manques);
		}
		return s;
	}

	list trier_evals_par_cout (list evals) {
		list triee <- [];
		list reste <- list(evals);
		loop while: length(reste) > 0 {
			map meilleur <- map(reste[0]);
			int idx_m <- 0;
			float cout_m <- (meilleur["plat"] as plat_item).cout_estime;
			int i <- 0;
			loop e over: reste {
				map em <- map(e);
				float c <- (em["plat"] as plat_item).cout_estime;
				if c < cout_m {
					meilleur <- em;
					cout_m <- c;
					idx_m <- i;
				}
				i <- i + 1;
			}
			triee <- triee + [meilleur];
			list nr <- [];
			int j <- 0;
			loop e over: reste {
				if j != idx_m {
					nr <- nr + [e];
				}
				j <- j + 1;
			}
			reste <- nr;
		}
		return triee;
	}

	list trier_evals_par_manques (list evals) {
		list triee <- [];
		list reste <- list(evals);
		loop while: length(reste) > 0 {
			map meilleur <- map(reste[0]);
			int idx_m <- 0;
			int nm <- int(meilleur["nb_manques"]);
			int i <- 0;
			loop e over: reste {
				map em <- map(e);
				int n <- int(em["nb_manques"]);
				if n < nm {
					meilleur <- em;
					nm <- n;
					idx_m <- i;
				}
				i <- i + 1;
			}
			triee <- triee + [meilleur];
			list nr <- [];
			int j <- 0;
			loop e over: reste {
				if j != idx_m {
					nr <- nr + [e];
				}
				j <- j + 1;
			}
			reste <- nr;
		}
		return triee;
	}

	map repas_echec (string type_r, string raison) {
		return [
			"type_repas"::type_r,
			"nom_plat"::"ECHEC_ARBITRAGE",
			"cout"::0.0,
			"ingredients_utilises"::[],
			"ingredients_a_acheter"::[],
			"magasin_suggere"::"",
			"salle_sport_suggeree"::"",
			"justification"::raison,
			"categorie_nutritionnelle"::"equilibre",
			"achat_necessaire"::false
		];
	}
}

/* ========== Household (apres les agents qu'il reference) ========== */
species household {
	string nom_foyer <- "Foyer";
	string label_carte <- "Foyer";
	string storage_mode <- "etalage";
	int nb_personnes <- 1;
	float budget_periode <- 50000.0;
	float budget_restant <- 50000.0;
	list restrictions_culturelles <- [];
	list allergies <- [];
	string regime <- "aucun";
	list provisions <- [];
	list historique_repas <- [];
	list plan_courant <- [];
	int alertes_nutritionnelles <- 0;
	bool necessite_achat <- false;
	int nb_repas_depuis_stock <- 0;
	int nb_repas_avec_achat <- 0;
	string derniere_salle_sport <- "";
	string dernier_plat <- "";
	string mission <- "repos";
	point position_maison;
	magasin magasin_cible;
	salle_de_sport salle_cible;

	agent_provisions mon_provisions;
	agent_budget mon_budget;
	agent_culture_restriction mon_culture;
	agent_nutrition mon_nutrition;
	agent_historique mon_historique;
	agent_logistique mon_logistique;
	agent_arbitrage mon_arbitrage;

	image_file icone_defaut <- image_file("../includes/icons/foyer.png");
	image_file icone_vegan <- image_file("../includes/icons/foyer_vegan.png");
	image_file icone_malbouffe <- image_file("../includes/icons/foyer_malbouffe.png");
	image_file icone_culture <- image_file("../includes/icons/foyer_culture.png");

	action creer_agents_decision {
		create agent_provisions number: 1 returns: ap {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_provisions <- ap[0];
		create agent_budget number: 1 returns: ab {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_budget <- ab[0];
		create agent_culture_restriction number: 1 returns: ac {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_culture <- ac[0];
		create agent_nutrition number: 1 returns: an {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_nutrition <- an[0];
		create agent_historique number: 1 returns: ah {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_historique <- ah[0];
		create agent_logistique number: 1 returns: al {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_logistique <- al[0];
		create agent_arbitrage number: 1 returns: aa {
			mon_foyer <- myself;
			location <- myself.location;
		}
		mon_arbitrage <- aa[0];
	}

	action initialiser_provisions (string niveau) {
		list base_noms <- [];
		list base_qte <- [];
		if niveau = "limite" or niveau = "faible" {
			base_noms <- ["riz", "huile", "oignon"];
			base_qte <- [2.0, 1.0, 2.0];
		} else if niveau = "riche" {
			base_noms <- ["riz", "huile", "oignon", "tomate", "haricot", "carotte", "tofu", "lait_coco",
				"feuilles_manioc", "champignon", "brede", "banane"];
			base_qte <- [10.0, 3.0, 5.0, 5.0, 4.0, 4.0, 3.0, 2.0, 3.0, 2.0, 3.0, 4.0];
		} else {
			base_noms <- ["riz", "huile", "oignon", "tomate", "poulet", "oeuf"];
			base_qte <- [5.0, 2.0, 3.0, 3.0, 2.0, 6.0];
		}
		loop i from: 0 to: length(base_noms) - 1 {
			create ingredient_stock number: 1 returns: stocks {
				nom <- base_noms[i];
				quantite <- float(base_qte[i]);
				provenance <- myself.storage_mode;
				foyer_proprietaire <- myself;
			}
			provisions <- provisions + stocks;
		}
	}

	list lister_noms_provisions {
		list noms <- [];
		loop s over: provisions {
			ingredient_stock st <- s as ingredient_stock;
			if st.quantite >= 1.0 {
				noms <- noms + [st.nom];
			}
		}
		return noms;
	}

	float stock_total_foyer {
		float total <- 0.0;
		loop s over: provisions {
			total <- total + (s as ingredient_stock).quantite;
		}
		return total;
	}

	action demander_plan {
		mission <- "repos";
		if activer_deplacement {
			location <- position_maison;
		}
		/* Gestion budget entre periodes. */
		if mode_budget = "reset" {
			budget_restant <- budget_periode;
		} else if mode_budget = "revenu" {
			budget_restant <- budget_restant + budget_periode;
		}
		/* mode persist : on ne recharge pas, le reste porte sur la suite. */
		necessite_achat <- false;
		derniere_salle_sport <- "";
		magasin_cible <- nil;
		salle_cible <- nil;
		ask mon_arbitrage {
			do generer_plan_periode;
		}
		historique_repas <- plan_courant;
		dernier_plat <- "aucun";
		loop repas_map over: plan_courant {
			map rm <- map(repas_map);
			string np <- string(rm["nom_plat"]);
			if np != "ECHEC_ARBITRAGE" {
				dernier_plat <- np;
			}
		}
		do preparer_mission;
	}

	action preparer_mission {
		if !activer_deplacement {
			mission <- "repos";
			return;
		}
		/* Priorite visuelle : alerte nutrition (salle) > achat (magasin). */
		if salle_cible != nil {
			mission <- "vers_salle";
		} else if necessite_achat and magasin_cible != nil {
			mission <- "vers_magasin";
		} else {
			mission <- "repos";
			location <- position_maison;
		}
	}

	reflex se_deplacer when: activer_deplacement {
		do avancer;
	}

	action avancer {
		if mission = "repos" {
			return;
		}
		point dest <- position_maison;
		if mission = "vers_magasin" and magasin_cible != nil {
			dest <- magasin_cible.location;
		} else if mission = "vers_salle" and salle_cible != nil {
			dest <- salle_cible.location;
		} else if mission = "retour" {
			dest <- position_maison;
		}

		float dist <- location distance_to dest;
		if dist <= vitesse_foyer {
			location <- dest;
			if mission = "vers_magasin" or mission = "vers_salle" {
				mission <- "retour";
			} else {
				mission <- "repos";
				location <- position_maison;
			}
		} else {
			location <- location + (((dest - location) / dist) * vitesse_foyer);
		}
	}

	aspect base {
		rgb halo <- #steelblue;
		if regime = "vegan" {
			halo <- #seagreen;
		} else if regime = "malbouffe_assumee" {
			halo <- #tomato;
		} else if ("pas_de_porc" in restrictions_culturelles) {
			halo <- #mediumpurple;
		}
		if activer_deplacement {
			if mission = "vers_magasin" {
				halo <- #orange;
			} else if mission = "vers_salle" {
				halo <- #red;
			} else if mission = "retour" {
				halo <- #gray;
			}
		}
		draw circle(3.4) color: halo border: #black;
		if afficher_icones {
			image_file ic <- icone_defaut;
			if regime = "vegan" {
				ic <- icone_vegan;
			} else if regime = "malbouffe_assumee" {
				ic <- icone_malbouffe;
			} else if ("pas_de_porc" in restrictions_culturelles) {
				ic <- icone_culture;
			}
			draw ic size: 5.5;
		}
		draw label_carte color: #black size: 10 at: location + {0.0, 5.2};
		/* Badge alerte : carre lisible (le petit cercle coupait les chiffres). */
		if alertes_nutritionnelles > 0 {
			point bp <- location + {5.5, -4.5};
			string txt_alerte <- "" + alertes_nutritionnelles;
			if alertes_nutritionnelles > 99 {
				txt_alerte <- "99+";
			}
			draw square(5.0) color: #red border: #white at: bp;
			draw txt_alerte color: #white size: 11 at: bp;
		}
	}
}
