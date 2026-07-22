#!/usr/bin/env bash
# Lance un ou tous les scenarios batch via Docker Compose,
# puis archive les CSV dans results/docker/<timestamp>/<scenario>/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCENARIO="${1:-all}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_ROOT="results/docker/${STAMP}"
MEMORY="${GAMA_MEMORY:-4096m}"

usage() {
  cat <<EOF
Usage: $0 [base|seuil|persist|pipeline|all]

  base      ScenarioBase (reference)
  seuil     ScenarioSeuilStrict
  persist   ScenarioBudgetPersist
  pipeline  ScenarioPipelineClassique
  all       les 4 scenarios (defaut)

Variables optionnelles :
  GAMA_MEMORY=4096m   memoire JVM passee a GAMA
EOF
}

service_for() {
  case "$1" in
    base) echo "scenario-base" ;;
    seuil) echo "scenario-seuil" ;;
    persist) echo "scenario-persist" ;;
    pipeline) echo "scenario-pipeline" ;;
    *) return 1 ;;
  esac
}

exp_for() {
  case "$1" in
    base) echo "ScenarioBase" ;;
    seuil) echo "ScenarioSeuilStrict" ;;
    persist) echo "ScenarioBudgetPersist" ;;
    pipeline) echo "ScenarioPipelineClassique" ;;
    *) return 1 ;;
  esac
}

archive_results() {
  local key="$1"
  local dest="${OUT_ROOT}/${key}"
  mkdir -p "$dest"
  if [ -f results/arbitrage_log.csv ]; then
    cp results/arbitrage_log.csv "$dest/arbitrage_log.csv"
  fi
  if [ -f results/conflits_log.csv ]; then
    cp results/conflits_log.csv "$dest/conflits_log.csv"
  fi
  case "$key" in
    base)
      cp -f results/conflits_log.csv results/scenarios/base_conflits.csv 2>/dev/null || true
      cp -f results/arbitrage_log.csv results/scenarios/base_arbitrage.csv 2>/dev/null || true
      ;;
    seuil)
      cp -f results/conflits_log.csv results/scenarios/seuil_conflits.csv 2>/dev/null || true
      ;;
    persist)
      cp -f results/conflits_log.csv results/scenarios/persist_conflits.csv 2>/dev/null || true
      ;;
    pipeline)
      cp -f results/conflits_log.csv results/scenarios/pipeline_conflits.csv 2>/dev/null || true
      ;;
  esac
  echo "  -> archives dans ${dest}"
}

run_one() {
  local key="$1"
  local service
  local exp
  service="$(service_for "$key")"
  exp="$(exp_for "$key")"
  echo ""
  echo "=== Docker batch : ${exp} (${service}) ==="
  mkdir -p results results/scenarios results/docker
  docker compose run --rm -e GAMA_MEMORY="$MEMORY" "$service"
  archive_results "$key"
}

if [ "$SCENARIO" = "-h" ] || [ "$SCENARIO" = "--help" ]; then
  usage
  exit 0
fi

echo "Laoka Lab — batch Docker (${STAMP})"
echo "Projet : $ROOT"

docker compose build

mkdir -p "$OUT_ROOT" results/scenarios

case "$SCENARIO" in
  all)
    for key in base seuil persist pipeline; do
      run_one "$key"
    done
    ;;
  base|seuil|persist|pipeline)
    run_one "$SCENARIO"
    ;;
  *)
    usage
    exit 1
    ;;
esac

echo ""
echo "=== Termine ==="
echo "Sorties : ${OUT_ROOT}"
ls -la "$OUT_ROOT" || true
