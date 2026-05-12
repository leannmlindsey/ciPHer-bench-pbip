#!/usr/bin/env bash
#SBATCH --job-name=pbip_smoke
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --gpus-per-node=1
#SBATCH --mem=8G
#SBATCH --time=00:10:00
#SBATCH --output=logs/smoke.%j.out
#SBATCH --error=logs/smoke.%j.err

# Submit FIRST. Verifies env, conda, tensorflow+tf-keras, model load,
# and UniRep feature files.
# Submit:
#   source pbip.env
#   sbatch --account="${ACCOUNT}" --partition="${PARTITION}" \
#          --gpus-per-node="${GPUS_PER_NODE}" delta/00_smoke_test.sbatch

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ ! -f "${REPO_ROOT}/pbip.env" ]]; then
    echo "FAIL: ${REPO_ROOT}/pbip.env missing." >&2
    echo "  cp config/pbip_delta.env pbip.env first." >&2
    exit 1
fi
# shellcheck disable=SC1091
source "${REPO_ROOT}/pbip.env"

mkdir -p "${REPO_ROOT}/logs"

echo "============================================================"
echo "PBIP smoke test"
echo "  hostname    : $(hostname)"
echo "  cpu arch    : $(uname -m)"
echo "============================================================"

echo
echo "[1/4] Conda activation"
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${PBIP_CONDA_ENV}"
echo "  active env: ${CONDA_DEFAULT_ENV}"
echo "  python:     $(python --version 2>&1)"

echo
echo "[2/4] Library check"
export TF_USE_LEGACY_KERAS=1
python <<'PY'
import sys
fails = []
for pkg in ["tensorflow", "tf_keras", "keras", "Bio", "pandas", "numpy", "sklearn"]:
    try:
        m = __import__(pkg if pkg != "Bio" else "Bio")
        ver = getattr(m, "__version__", "n/a")
        print(f"  OK  {pkg:14} {ver}")
    except Exception as e:
        print(f"  FAIL {pkg:14} {e}")
        fails.append(pkg)
if fails:
    sys.exit(2)
PY

echo
echo "[3/4] Data layout"
: "${PBIP_DATA_DIR:?pbip.env broken}"
echo "  PBIP_DATA_DIR      = ${PBIP_DATA_DIR}"
echo "  PBIP_REPO          = ${PBIP_REPO}"
echo "  CIPHER_VAL_GENOMES = ${CIPHER_VAL_GENOMES}"

declare -a checks=(
    "${PBIP_REPO}/model/dataset_PBIP/final_model.h5"
    "${PBIP_REPO}/data/PBIP/host"
    "${PBIP_REPO}/data/PBIP/phage"
    "${CIPHER_VAL_GENOMES}/PBIP/metadata/interaction_matrix.tsv"
)
for f in "${checks[@]}"; do
    if [[ -e "${f}" ]]; then
        if [[ -d "${f}" ]]; then
            N=$(ls -1 "${f}" 2>/dev/null | wc -l)
            echo "  OK : ${f}  (${N} files)"
        else
            echo "  OK : ${f}"
        fi
    else
        echo "  FAIL: missing ${f}" >&2
        exit 3
    fi
done

# Specific counts
N_HOST=$(ls -1 "${PBIP_REPO}/data/PBIP/host"  | wc -l)
N_PHAGE=$(ls -1 "${PBIP_REPO}/data/PBIP/phage" | wc -l)
if [ "${N_HOST}" != "120" ]; then
    echo "  WARN: expected 120 host UniRep files, found ${N_HOST}" >&2
fi
if [ "${N_PHAGE}" != "103" ]; then
    echo "  WARN: expected 103 phage UniRep files, found ${N_PHAGE}" >&2
fi

echo
echo "[4/4] PBIP final_model.h5 load test (tf-keras + Keras 2 shim)"
python <<'PY'
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["CUDA_VISIBLE_DEVICES"] = ""
import tf_keras as keras
from pathlib import Path
h5 = Path(os.environ["PBIP_REPO"]) / "model" / "dataset_PBIP" / "final_model.h5"
print(f"  loading {h5}...")
m = keras.models.load_model(h5)
print(f"  OK — {m.count_params():,} params, {len(m.layers)} layers")
PY

echo
echo "All smoke checks passed."
echo "Now you can submit a real inference, e.g. via:"
echo "  ./scripts/run_pbip_on_pbip_dataset.sh"
