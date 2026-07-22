# Laoka Lab

Simulation multi-agents (**GAMA / GAML**) du moteur de recommandation de repas **« Inona ny laoka »** (« quel plat » en malgache).

Ce n’est **pas** l’app mobile finale. C’est un **laboratoire de décision** : plusieurs contraintes négocient un plan de repas, et on mesure où ça coince.

Compatible **GAMA Platform 2025.6+**.

---

## Démarrage rapide

1. Ouvrir GAMA → projet `LaokaLab`
2. Ouvrir **`models/LaokaLab.gaml`** (toujours ce fichier)
3. Lancer **`LaokaLabUI`**
4. Laisser tourner jusqu’à *« Fin automatique »* (~40 plans)

**Astuce anti-scintillement :** laisser **Activer deplacement = OFF** (défaut). L’activer seulement pour une démo visuelle.

---

## Architecture des agents

| Contrainte | Agent | Type |
|---|---|---|
| Culture / allergies | `agent_culture_restriction` | **Dur** (non négociable) |
| Budget | `agent_budget` (+ score) | Soft |
| Nutrition | `agent_nutrition` (+ score) | Soft |
| Stock | `agent_provisions` (+ score) | Soft |
| Historique | `agent_historique` (+ score) | Soft |
| Magasin / salle | `agent_logistique` | Spatial |
| Synthèse | `agent_arbitrage` | Scores pondérés |

Chaque `household` a **ses propres** instances d’agents.

### Modes importants

| Paramètre | Valeurs | Effet |
|---|---|---|
| `mode_budget` | `revenu` / `reset` / `persist` | Report + allocation / recharge totale / jamais |
| `utiliser_negociation_scores` | true / false | Scores vs ancien pipeline séquentiel |
| `nb_plans_max` | 10–100 | Arrêt automatique |
| `activer_deplacement` | true / false | Animation magasin/salle (démo) |

---

## Personas

| Foyer | Profil |
|---|---|
| Malgache | Famille 5 pers., stock limité, budget serré |
| Européen | Solo, allergie fruits de mer |
| Sans porc | Restriction culturelle |
| Vegan | Régime vegan, stock riche |
| Défaut | Profil moyen |
| Malbouffe | Malbouffe assumée → alertes |

---

## Experiments

| Experiment | Rôle |
|---|---|
| `LaokaLabUI` | Démo + analyse interactive |
| `ScenarioBase` | Référence : revenu + scores, 30 plans |
| `ScenarioSeuilStrict` | Seuil alerte nutrition = 3 |
| `ScenarioBudgetPersist` | Budget sans recharge |
| `ScenarioPipelineClassique` | Ancien pipeline + reset (baseline) |

### Headless

```bash
/Applications/Gama.app/Contents/headless/gama-headless.sh \
  -m 4096m -ws /tmp/gama_ws \
  -batch ScenarioBase \
  "/chemin/vers/LaokaLab/models/LaokaLab.gaml"
```

---

## Structure

```text
LaokaLab/
├── models/
│   ├── LaokaLab.gaml           # Entrée + experiments
│   ├── global/InitMonde.gaml   # Monde, personas
│   ├── global/CycleSimu.gaml   # Boucle + exports
│   └── species/Agents.gaml + Entites.gaml
├── includes/plats.csv, icons/, gis/
├── results/                    # CSV de sortie
├── RESULTATS.md                # Synthèse pour mémoire / soutenance
└── README.md
```

---

## Lire les sorties

| Fichier | Contenu |
|---|---|
| `results/arbitrage_log.csv` | Résumé par foyer / plan |
| `results/conflits_log.csv` | Métriques de conflit par plan |
| `RESULTATS.md` | Interprétation comparative |

### Ligne console typique

```text
Plan 10/40 | stock 58% | malbouffe 7% | budg rest 5166 | rejet cult 15% | rejet budg 66% | alertes 1 [Malbouffe]
```

- **stock %** : repas cuisinés sans achat immédiat  
- **malbouffe %** : part de plats junk  
- **budg rest** : budget moyen restant  
- **rejet cult / budg** : pression des filtres  
- **alertes** : foyers en alerte nutrition ce plan  

---

## Prérequis

- [GAMA Platform](https://gama-platform.org/) 2025.6+
- Java fourni avec GAMA

## Auteur

[Andassa](https://github.com/Andassa) — labo R&D recommandation de repas (contexte Madagascar).
