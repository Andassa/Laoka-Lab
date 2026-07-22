/**
 * Boucle de simulation : plans, metriques de conflit, export, arret automatique.
 */
model CycleSimu

import "../species/Agents.gaml"

global {
	int nb_plans_sans_conflit <- 0;
	int nb_plans_avec_achat <- 0;
	int nb_repas_stock_total <- 0;
	int nb_repas_achat_total <- 0;
	float part_repas_stock <- 0.0;
	float budget_moyen_consomme <- 0.0;
	float somme_budgets_consommes <- 0.0;
	string journal_alertes_cycle <- "";
	string resume_choix_cycle <- "";
	int dernier_cycle_plan <- -999;

	bool tous_foyers_au_repos {
		loop h over: household {
			if h.mission != "repos" {
				return false;
			}
		}
		return true;
	}

	reflex cycle_recommandation when: !simulation_terminee
		and (cycle - dernier_cycle_plan >= pas_entre_plans)
		and (!activer_deplacement or tous_foyers_au_repos()) {
		dernier_cycle_plan <- cycle;
		nb_plans_sans_conflit <- 0;
		nb_plans_avec_achat <- 0;
		nb_repas_stock_total <- 0;
		nb_repas_achat_total <- 0;
		nb_alertes_ce_cycle <- 0;
		rejets_culture_plan <- 0;
		rejets_budget_plan <- 0;
		evitements_hist_plan <- 0;
		repas_malbouffe_plan <- 0;
		repas_equilibre_plan <- 0;
		somme_budgets_consommes <- 0.0;
		journal_alertes_cycle <- "";
		resume_choix_cycle <- "";

		ask household {
			float budget_avant <- budget_restant;
			do demander_plan;
			float depense <- 0.0;
			if mode_budget = "revenu" {
				depense <- budget_avant + budget_periode - budget_restant;
			} else if mode_budget = "reset" {
				depense <- budget_periode - budget_restant;
			} else {
				depense <- budget_avant - budget_restant;
			}
			if depense < 0.0 {
				depense <- 0.0;
			}
			somme_budgets_consommes <- somme_budgets_consommes + depense;
			nb_repas_stock_total <- nb_repas_stock_total + nb_repas_depuis_stock;
			nb_repas_achat_total <- nb_repas_achat_total + nb_repas_avec_achat;
			if necessite_achat {
				nb_plans_avec_achat <- nb_plans_avec_achat + 1;
			} else {
				nb_plans_sans_conflit <- nb_plans_sans_conflit + 1;
			}
			if resume_choix_cycle = "" {
				resume_choix_cycle <- label_carte + ":" + dernier_plat;
			} else {
				resume_choix_cycle <- resume_choix_cycle + " | " + label_carte + ":" + dernier_plat;
			}
			if derniere_salle_sport != "" {
				if journal_alertes_cycle = "" {
					journal_alertes_cycle <- label_carte;
				} else {
					journal_alertes_cycle <- journal_alertes_cycle + "," + label_carte;
				}
			}
		}

		float somme_stocks <- 0.0;
		float somme_budgets_restants <- 0.0;
		ask household {
			somme_stocks <- somme_stocks + stock_total_foyer();
			somme_budgets_restants <- somme_budgets_restants + budget_restant;
		}
		if length(household) > 0 {
			budget_moyen_consomme <- somme_budgets_consommes / length(household);
			stock_moyen_foyers <- somme_stocks / length(household);
			budget_moyen_restant <- somme_budgets_restants / length(household);
		} else {
			budget_moyen_consomme <- 0.0;
			stock_moyen_foyers <- 0.0;
			budget_moyen_restant <- 0.0;
		}

		int total_repas <- nb_repas_stock_total + nb_repas_achat_total;
		if total_repas > 0 {
			part_repas_stock <- (100.0 * nb_repas_stock_total) / total_repas;
			pct_malbouffe <- (100.0 * repas_malbouffe_plan) / total_repas;
		} else {
			part_repas_stock <- 0.0;
			pct_malbouffe <- 0.0;
		}

		int n_cat <- length(catalogue_plats);
		if total_repas > 0 and n_cat > 0 {
			pct_rejet_culture <- (100.0 * rejets_culture_plan) / (total_repas * n_cat);
			pct_rejet_budget <- (100.0 * rejets_budget_plan) / (total_repas * n_cat);
		} else {
			pct_rejet_culture <- 0.0;
			pct_rejet_budget <- 0.0;
		}

		nb_plans_faits <- nb_plans_faits + 1;
		do exporter_resultats;
		do exporter_conflits;

		string suffixe_alerte <- "";
		if journal_alertes_cycle != "" {
			suffixe_alerte <- " [" + journal_alertes_cycle + "]";
		}
		write "Plan " + nb_plans_faits + "/" + nb_plans_max
			+ " @" + cycle
			+ " | stock " + int(part_repas_stock) + "%"
			+ " | malbouffe " + int(pct_malbouffe) + "%"
			+ " | budg rest " + int(budget_moyen_restant)
			+ " | rejet cult " + int(pct_rejet_culture) + "%"
			+ " | rejet budg " + int(pct_rejet_budget) + "%"
			+ " | alertes " + nb_alertes_ce_cycle
			+ suffixe_alerte;

		if nb_plans_faits >= nb_plans_max {
			simulation_terminee <- true;
			write "=== Fin automatique : " + nb_plans_faits + " plans atteints ===";
			write "Resume final | stock " + int(part_repas_stock) + "%"
				+ " | malbouffe " + int(pct_malbouffe) + "%"
				+ " | alertes cumul " + nb_alertes_nutritionnelles_total
				+ " | unites achetees " + nb_unites_achetees_total;
		}
	}

	action exporter_resultats {
		ask household {
			string mag_nom <- "";
			if magasin_cible != nil {
				mag_nom <- magasin_cible.nom;
			}
			string ligne <- "" + cycle + ";" + nom_foyer + ";resume;"
				+ dernier_plat + ";" + (budget_periode - budget_restant) + ";"
				+ "stock=" + int(stock_total_foyer()) + ";"
				+ mag_nom + ";"
				+ derniere_salle_sport + ";"
				+ necessite_achat + ";" + alertes_nutritionnelles;
		save (ligne + "\n") to: "../results/arbitrage_log.csv" format: "text" rewrite: false;
		}
	}

	action exporter_conflits {
		string ligne <- "" + cycle + ";" + nb_plans_faits + ";"
			+ int(part_repas_stock) + ";" + int(stock_moyen_foyers) + ";"
			+ nb_alertes_ce_cycle + ";" + int(pct_malbouffe) + ";"
			+ int(pct_rejet_culture) + ";" + int(pct_rejet_budget) + ";"
			+ evitements_hist_plan + ";"
			+ repas_malbouffe_plan + ";" + repas_equilibre_plan + ";"
			+ rejets_culture_plan + ";" + rejets_budget_plan;
		save (ligne + "\n") to: "../results/conflits_log.csv" format: "text" rewrite: false;
	}
}
