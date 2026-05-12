#!/usr/bin/env bash
# Run PBIP's in-distribution evaluation on cipher's PBIP validation matrix
# using paths from pbip.env.
#
# Usage:
#   source pbip.env
#   ./scripts/run_pbip_on_pbip_dataset.sh
set -euo pipefail

: "${PBIP_REPO:?source pbip.env first}"
: "${CIPHER_VAL_GENOMES:?source pbip.env first}"
: "${PBIP_OUTPUT_ROOT:?source pbip.env first}"

OUT_DIR="${PBIP_OUTPUT_ROOT}/PBIP"
mkdir -p "${OUT_DIR}"

python "$(dirname "$0")/run_pbip_inference.py" \
    --phage_unirep_dir   "${PBIP_REPO}/data/PBIP/phage" \
    --host_unirep_dir    "${PBIP_REPO}/data/PBIP/host" \
    --model_h5           "${PBIP_REPO}/model/dataset_PBIP/final_model.h5" \
    --interaction_matrix "${CIPHER_VAL_GENOMES}/PBIP/metadata/interaction_matrix.tsv" \
    --out_csv            "${OUT_DIR}/prediction_scores.csv"
