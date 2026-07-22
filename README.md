# Laoka Lab

Simulation multi-agents (GAMA / GAML) du moteur de recommandation de repas **« Inona ny laoka »** (« quel plat / accompagnement » en malgache).

Ce dépôt n’est **pas** l’application mobile finale (pas de RAG, pas de LLM, pas de vraie base utilisateurs).  
C’est un **laboratoire de décision** : plusieurs contraintes négocient pour produire un plan de repas, et la carte + les graphiques montrent où ça coince.

Compatible **GAMA Platform 2025.x**.

---

## À quoi ça sert ?

Pour un ou plusieurs **foyers**, la simulation génère un plan de repas (petit-déjeuner / déjeuner / dîner) sur une période (`jour`, `semaine` ou `mois`) en tenant compte de :

| Contrainte | Agent | Effet |
|---|---|---|
| Stock disponible | `agent_provisions` | Quels plats sont faisables ? Que manque-t-il ? |
| Budget | `agent_budget` | Filtre les plats trop chers (tolérance soft configurable) |
| Culture / allergies | `agent_culture_restriction` | Rejet strict (ex. pas de porc, vegan, allergènes) |
| Nutrition | `agent_nutrition` | Pousse vers l’équilibre ; alerte si trop de malbouffe |
| Historique | `agent_historique` | Évite de répéter le même plat |
| Logistique | `agent_logistique` | Magasin / salle de sport les plus proches (chemin spatial) |
| Synthèse | `agent_arbitrage` | Orchestre la priorité et construit le plan final |

Chaque `household` possède **ses propres** instances de ces agents (pas un seul pipeline global partagé).

---

## Ce que fait un cycle de simulation

1. Chaque foyer recharge son budget de période et demande un plan.
2. L’arbitrage enchaîne les filtres dans l’ordre :  
   **culture → budget → historique → nutrition → provisions / achats**.
3. Si des ingrédients manquent → suggestion du **magasin** le mieux placé sur le graphe du quartier.
4. Si trop de malbouffe (seuil paramétrable) → **alerte nutritionnelle** + suggestion de **salle de sport** proche.
5. Export d’une ligne CSV par repas dans `results/arbitrage_log.csv`.
6. Les moniteurs / graphiques mettent à jour : budget moyen, achats, répétitions évitées, alertes cumulées.

> Note : avec la logique actuelle, le stock n’est pas réellement consommé/rechargé après achat, et le budget est réinitialisé à chaque cycle. Certaines courbes restent donc stables ou linéaires (comportement attendu, pas un bug d’affichage).

---

## Personas (foyers) inclus

| Foyer | Profil |
|---|---|
| Foyer Malgache | Famille, stock limité, budget serré |
| Foyer Européen | Solo, frigidaire, allergie fruits de mer |
| Foyer Sans Porc | Restriction culturelle stricte |
| Foyer Vegan | Régime vegan, stock riche |
| Foyer Défaut | Profil « moyen » |
| Foyer Malbouffe | Choisit volontairement la malbouffe → alertes |

---

## Structure du projet

```text
LaokaLab/
├── models/
│   ├── LaokaLab.gaml          # Point d’entrée : global, init, experiments
│   └── species/
│       ├── Entites.gaml       # plat_item, stock, magasin, salle_de_sport
│       └── Agents.gaml        # pipeline de décision + household
├── includes/
│   ├── plats.csv              # Catalogue de plats
│   └── icons/                 # Icônes PNG (+ SVG source) pour la carte
├── results/                   # Exports CSV de simulation
├── .project                   # Projet Eclipse / GAMA
└── README.md
```

---

## Affichage (icônes)

Sur la carte du quartier :

- **Maison** = foyer (couleur selon régime / restriction)
- **Magasin** = point d’achat
- **Haltères** = salle de sport

Fichiers : `includes/icons/*.png` (utilisés par GAMA via `image_file`).  
Les `.svg` sont fournis comme sources vectorielles.

---

## Lancer la simulation dans GAMA

1. Ouvrir GAMA Platform.
2. Importer / ouvrir le projet `LaokaLab`.
3. Ouvrir **`models/LaokaLab.gaml`** (pas les modules seuls).
4. Lancer l’expérience GUI **`LaokaLabUI`**.

Paramètres utiles dans le panneau gauche :

- Période (`jour` / `semaine` / `mois`)
- Nombre de foyers (1–6)
- Seuil d’alerte nutrition
- Budget par défaut / tolérance de dépassement

Expérience batch : **`ExportBatch`** (quelques cycles, utile en headless).

### Headless (exemple)

```bash
/Applications/Gama.app/Contents/headless/gama-headless.sh \
  -m 4096m -ws /tmp/gama_ws \
  -batch ExportBatch \
  /chemin/vers/LaokaLab/models/LaokaLab.gaml
```

---

## Pipeline de priorité (rappel)

```text
catalogue
   → filtre culture / allergies (dur)
   → filtre budget (+ tolérance soft)
   → anti-répétition historique
   → orientation nutrition
   → évaluation stock / manques
   → si manque : magasin le plus proche
   → si alerte nutrition : salle de sport la plus proche
   → plan de période + justification textuelle
```

---

## Résultats

Fichier principal : `results/arbitrage_log.csv`

Colonnes typiques : cycle, foyer, type de repas, plat, coût, justification, magasin, salle de sport, achat nécessaire, alertes.

---

## Prérequis

- [GAMA Platform](https://gama-platform.org/) **2025.6+** recommandé
- Java fourni avec GAMA (ou JDK 21)

---

## Auteur

Compte GitHub : [Andassa](https://github.com/Andassa)  
Projet : simulation pédagogique / R&D autour d’un moteur de recommandation de repas contextuel à Madagascar.
