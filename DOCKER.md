# Docker — Laoka Lab (batch GAMA headless + CI)

Objectif : **reproduire les expériences batch** sans installer l’IDE GAMA, et les lancer en **CI GitHub Actions**.

Ce n’est **pas** pour l’UI (`LaokaLabUI`) — la démo interactive reste dans GAMA desktop.

---

## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (ou Docker Engine + Compose v2)
- ~6 Go RAM alloués à Docker
- Sur **Mac Apple Silicon** : l’image officielle GAMA est `linux/amd64` (émulation OK, un peu plus lente)

Image de base : [`gamaplatform/gama:2025.06.4`](https://hub.docker.com/r/gamaplatform/gama)

---

## Démarrage rapide

Depuis le dossier `LaokaLab/` :

```bash
# 1) Build l'image (modele embarque)
docker compose build

# 2) Un scenario
docker compose run --rm scenario-base

# 3) Les 4 scenarios + archivage CSV
chmod +x scripts/run-docker-batches.sh
./scripts/run-docker-batches.sh all
```

Sorties :
- `results/arbitrage_log.csv` / `results/conflits_log.csv` (dernier run)
- `results/docker/<timestamp>/<scenario>/` (archives du script)

---

## Services Compose

| Service | Experiment GAMA |
|---|---|
| `scenario-base` | `ScenarioBase` |
| `scenario-seuil` | `ScenarioSeuilStrict` |
| `scenario-persist` | `ScenarioBudgetPersist` |
| `scenario-pipeline` | `ScenarioPipelineClassique` |

Exemple :

```bash
docker compose run --rm scenario-pipeline
```

Mémoire JVM (optionnel) :

```bash
GAMA_MEMORY=6144m ./scripts/run-docker-batches.sh base
```

---

## CI GitHub Actions

Fichier : `.github/workflows/batch-docker.yml`

- **push / PR** (changements models/includes/Docker) → lance `ScenarioBase`
- **workflow_dispatch** → choix `base|seuil|persist|pipeline|all`
- Artefacts CSV uploadés (14 jours)

Onglet Actions → *Batch Docker GAMA* → *Run workflow*.

---

## Architecture

```text
Dockerfile              # FROM gamaplatform/gama + COPY projet
docker-compose.yml      # 4 services batch
scripts/run-docker-batches.sh
.github/workflows/batch-docker.yml
```

Le volume `./:/work` permet d’écrire les CSV sur ta machine tout en utilisant l’image buildée.

---

## Dépannage

| Problème | Piste |
|---|---|
| `platform` / exec format | Forcer `platform: linux/amd64` (déjà dans compose) |
| OOM / crash JVM | Augmenter RAM Docker + `GAMA_MEMORY=6144m` |
| CSV absents | Vérifier droits `results/` ; relancer avec volume monté |
| Build lent | Normal la 1re fois (pull ~350 Mo GAMA) |

---

## Licence données GIS

Les runs Docker utilisent le même shapefile OSM (`includes/gis/`) — © OpenStreetMap contributors, ODbL.
