/**
 * Boucle de simulation : plans, metriques, export CSV.
 */
model CycleSimu

import "../species/Agents.gaml"

global {
	int nb_plans_sans_conflit <- 0;
	int nb_plans_avec_achat <- 0;
	float budget_moyen_consomme <- 0.0;
	float somme_budgets_consommes <- 0.0;
	string journal_alertes_cycle <- "";

	reflex cycle_recommandation {
		nb_plans_sans_conflit <- 0;
		nb_plans_avec_achat <- 0;
		somme_budgets_consommes <- 0.0;
		journal_alertes_cycle <- "";
		ask household {
			do demander_plan;
			somme_budgets_consommes <- somme_budgets_consommes + (budget_periode - budget_restant);
			if necessite_achat {
				nb_plans_avec_achat <- nb_plans_avec_achat + 1;
			} else {
				nb_plans_sans_conflit <- nb_plans_sans_conflit + 1;
			}
			if derniere_salle_sport != "" {
				if journal_alertes_cycle = "" {
					journal_alertes_cycle <- nom_foyer + "->" + derniere_salle_sport;
				} else {
					journal_alertes_cycle <- journal_alertes_cycle + " ; " + nom_foyer + "->" + derniere_salle_sport;
				}
			}
		}
		if length(household) > 0 {
			budget_moyen_consomme <- somme_budgets_consommes / length(household);
		} else {
			budget_moyen_consomme <- 0.0;
		}
		do exporter_resultats;
		string suffixe <- "";
		if journal_alertes_cycle != "" {
			suffixe <- " | alerte: " + journal_alertes_cycle;
		}
		write "Cycle " + cycle
			+ " | sans conflit: " + nb_plans_sans_conflit
			+ " | achat: " + nb_plans_avec_achat
			+ " | alertes total: " + nb_alertes_nutritionnelles_total
			+ " | budget moy: " + int(budget_moyen_consomme)
			+ suffixe;
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
