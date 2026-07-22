# Résultats Laoka Lab — synthèse pour mémoire / soutenance

Simulation multi-agents du moteur de recommandation **« Inona ny laoka »** (GAMA 2025.6).  
Runs batch : **30 plans**, période **semaine**, 6 foyers, catalogue 35 plats.

---

## 1. Scénarios comparés

| Scénario | Config | Objectif |
|---|---|---|
| **Base** | Scores ON, budget `revenu`, seuil 5 | Référence actuelle |
| **SeuilStrict** | Idem, seuil alerte = 3 | Sensibilité du seuil nutrition |
| **Persist** | Scores ON, budget `persist` | Effet d’un budget qui ne se recharge pas |
| **Pipeline** | Scores OFF, budget `reset` | Baseline « ancienne » version |

Fichiers logs bruts des runs : générés en headless (résumés ci-dessous).  
Exports CSV : `results/arbitrage_log.csv`, `results/conflits_log.csv`.

---

## 2. Tableau comparatif (fin de run + moyennes)

| Indicateur | Base | SeuilStrict | Persist | Pipeline |
|---|---:|---:|---:|---:|
| Stock moyen (avg plans) | **59,5 %** | 59,5 % | 57,7 % | 50,8 % |
| Stock final | **60 %** | 60 % | 56 % | 54 % |
| Malbouffe moyenne | **8,8 %** | 8,8 % | 7,8 % | 23,2 % |
| Malbouffe finale | **6 %** | 6 % | 4 % | **34 %** |
| Alertes / plan (moy.) | **0,90** | 0,93 | 1,00 | **3,00** |
| Alertes cumul (30 plans) | **27** | 28 | 30 | **90** |
| Rejet budget moyen | 64,6 % | 64,6 % | **83,5 %** | 70,6 % |
| Unités achetées | 2772 | 2772 | 2804 | 2894 |

---

## 3. Interprétation

### 3.1 La négociation par scores améliore nettement la nutrition

Comparer **Base** vs **Pipeline** :

- Malbouffe finale : **6 %** vs **34 %**
- Alertes cumulées : **27** vs **90**
- Stock moyen : **59,5 %** vs **50,8 %**

→ Les scores (budget + nutrition + stock + historique), avec culture en contrainte dure, produisent des plans **plus sains** et un meilleur usage du stock.

### 3.2 Le budget reste la contrainte dominante

Dans tous les scénarios « scores », le **rejet budgétaire** oscille autour de **65 %** (et monte à **83 %** en `persist`).  
Le rejet culturel reste stable à **~15 %** (allergies / vegan / porc).

→ Pour un moteur type « Inona ny laoka », **l’enveloppe budgétaire** est le principal goulot d’étranglement, devant la culture.

### 3.3 Seuil d’alerte 3 vs 5 : effet faible sous scores

Base (seuil 5) et SeuilStrict (seuil 3) sont quasi identiques (27 vs 28 alertes).  
Avec les scores qui freinent déjà la malbouffe, baisser le seuil change peu le comportement agrégé.

→ Le levier « seuil » est secondaire tant que la négociation favorise l’équilibre.

### 3.4 Budget `persist` : contrainte plus dure, malbouffe encore plus basse

Sans recharge, la pression budget monte (**83 %**), le stock baisse un peu, la malbouffe finale tombe à **4 %**.  
Les foyers sont poussés vers des plats moins chers / plus faisables.

### 3.5 Alertes concentrées sur le persona Malbouffe

Sous scores + revenu, les alertes sont typiquement **0 ou 1 par plan**, presque toujours **[Malbouffe]**.  
C’est cohérent avec le design du persona `malbouffe_assumee`.

---

## 4. Phrase type pour un rapport

> Sur 30 plans hebdomadaires et 6 personas, le mode scores + budget revenu aboutit à ~60 % de repas issus du stock et ~6–9 % de malbouffe, contre ~34 % de malbouffe et trois fois plus d’alertes avec l’ancien pipeline. La contrainte budgétaire reste la plus sélective (~65 % de plats hors enveloppe), tandis que les alertes nutritionnelles se concentrent sur le foyer Malbouffe.

---

## 5. Graphes à montrer en soutenance (UI)

Dans `LaokaLabUI`, après un run de 40 plans :

1. **Stock %** — stabilité autour de 55–65 %  
2. **Budget restant** — décroissance puis oscillation (mode revenu)  
3. **Conflits** — culture plate, budget haut, malbouffe basse  
4. **Alertes** — pics à 1 (Malbouffe)

Comparer éventuellement un run `ScenarioPipelineClassique` pour le contraste.

---

## 6. Limites (à mentionner)

- Quartiers **et** shapefile OSM centre Antananarivo (`includes/gis/antananarivo_roads.shp`, 1136 routes, ODbL)
- Catalogue de **35 plats** (échantillon)
- Pas de périssabilité fine des stocks
- Négociation via **votes `ask` + scores** (pas de protocole FIPA complet)

---

## 7. Évolutions post-valorisation

- Votes agents soft (`voter_plat`) collectés par `ask` dans l’arbitrage
- Plancher d’épargne (`ratio_epargne_min`, défaut 8 %) : budget dépensable hors réserve
- Carte avec 6 quartiers nommés (Analakely, Isotry, Andraharo, Antaninarenina, Mahamasina, Ivandry)

---

## 8. Conclusion projet

Le laboratoire SMA atteint son objectif : **montrer et mesurer** comment provisions, budget, culture, nutrition, historique et logistique co-construisent un plan de repas.  
La version scores + budget revenu (+ épargne min) est la configuration de référence recommandée pour la démo et le mémoire.
