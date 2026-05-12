#!/usr/bin/env bash
# Build ciPHer-bench-pbip-data.zip from the laptop.
# Output: /Users/leannmlindsey/Desktop/ciPHer-bench-data-zips/ciPHer-bench-pbip-data.zip
#
# Layout MIRRORS the laptop layout under data/ so env vars (PBIP_REPO,
# CIPHER_VAL_GENOMES) keep working unchanged.
#
# Contents (extracts to data/ on Delta):
#   data/PBIP/                              Upstream + GDrive download:
#                                           model/, data/, bac_faa_2021/,
#                                           phage_faa_2021/, bac_fasta_*,
#                                           phage_fasta_* (~1.6 GB)
#   data/cipher_val_genomes/PBIP/metadata/  cipher's PBIP interaction matrix
#                                           (mirror of the corresponding cipher
#                                           tree path)
#   data/cipher/data/validation_data/HOST_RANGE/PBIP/metadata/
#                                           (same file, also at the cipher_repo
#                                           mirror path)
#
# Run from the laptop.
set -euo pipefail

SRC_PBIP="/Users/leannmlindsey/WORK/CLAUDE_DPOTROPISEARCH/claude_copy/DpoTropiSearch/benchmark_external/pbip_run/PBIP"
SRC_CIPHER="/Users/leannmlindsey/WORK/PHI_TSP/cipher"
OUT_DIR="/Users/leannmlindsey/Desktop/ciPHer-bench-data-zips"
STAGE_PARENT="$(mktemp -d -t pbip-data-zip-XXXXXX)"
STAGE_DIR="${STAGE_PARENT}/data"
ZIP_PATH="${OUT_DIR}/ciPHer-bench-pbip-data.zip"

mkdir -p "${OUT_DIR}" "${STAGE_DIR}"

if [ ! -d "${SRC_PBIP}" ]; then
    echo "ERROR: PBIP upstream not found at ${SRC_PBIP}" >&2
    echo "  Download the 6 zips from the upstream Google Drive folder first." >&2
    exit 1
fi

echo "[1/3] PBIP upstream + GDrive contents (~1.6 GB)"
mkdir -p "${STAGE_DIR}/PBIP"
rsync -a --exclude '__pycache__' "${SRC_PBIP}/" "${STAGE_DIR}/PBIP/"

echo "[2/3] cipher mirror (PBIP metadata)"
SRC="${SRC_CIPHER}/data/validation_data/HOST_RANGE/PBIP/metadata"
if [ -d "${SRC}" ]; then
    DST="${STAGE_DIR}/cipher/data/validation_data/HOST_RANGE/PBIP/metadata"
    mkdir -p "${DST}"
    cp -R "${SRC}/." "${DST}/"
fi

echo "[3/3] cipher_val_genomes mirror (PBIP metadata, dual-mounted)"
mkdir -p "${STAGE_DIR}/cipher_val_genomes/PBIP/metadata"
cp -R "${SRC}/." "${STAGE_DIR}/cipher_val_genomes/PBIP/metadata/" 2>/dev/null || true

echo "  staged total: $(du -sh "${STAGE_DIR}" | cut -f1)"

echo "[zip] (fast compression)"
cd "${STAGE_PARENT}"
zip -qr -1 "${ZIP_PATH}" data
du -sh "${ZIP_PATH}"

rm -rf "${STAGE_PARENT}"

echo
echo "Done. Zip at: ${ZIP_PATH}"
