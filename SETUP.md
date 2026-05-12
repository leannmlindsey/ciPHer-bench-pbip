# Setup + reproduce

## 1. Clone upstream PBIP + download Google Drive contents

```bash
# Wherever PBIP_REPO in your env points:
git clone https://github.com/a1678019300/PBIP.git "$PBIP_REPO"
```

The repo on its own won't run — PBIP's README points at a Google Drive
folder for the trained weights + UniRep features + raw FASTAs:

  https://drive.google.com/drive/folders/1c1JNePxM5IFlTqt6CglUHWi-J-Z_1uoo

Download the six zips manually from that folder:
- `bac_faa.zip`
- `bac_fasta.zip`
- `data.zip`             ← contains data/PBIP/{host,phage}/ UniRep features
- `model.zip`            ← contains model/dataset_PBIP/final_model.h5
- `phage_faa.zip`
- `phage_fasta.zip`

Extract all six into `$PBIP_REPO/` so the final layout is:

```
$PBIP_REPO/
├── data/PBIP/host/*.txt          # 120 host UniRep 1900-d vectors
├── data/PBIP/phage/*.txt         # 103 phage UniRep 1900-d vectors
├── model/dataset_PBIP/final_model.h5   # ~40 MB Keras 2 model
├── bac_faa_2021/                 # raw bacterial AA FASTAs
├── phage_faa_2021/               # raw phage AA FASTAs
└── ...
```

## 2. Build the conda env

```bash
conda create -n pbip python=3.10 -y
conda activate pbip
pip install tensorflow tf-keras keras imbalanced-learn pandas scikit-learn biopython numpy
```

The `tf-keras` package provides the Keras 2 API even when TensorFlow 2.x
is installed — required because PBIP's `final_model.h5` was saved with
Keras 2. The wrapper sets `TF_USE_LEGACY_KERAS=1` to route Keras imports
through the shim.

## 3. Configure paths

```bash
cp config/pbip.env.template pbip.env       # laptop
# or:
cp config/pbip_delta.env    pbip.env
cp config/pbip_biowulf.env  pbip.env

pico pbip.env
source pbip.env

echo "PBIP_REPO=$PBIP_REPO"
echo "CIPHER_VAL_GENOMES=$CIPHER_VAL_GENOMES"
ls "$PBIP_REPO/model/dataset_PBIP/final_model.h5"   # should exist (~40 MB)
ls "$PBIP_REPO/data/PBIP/host"   | wc -l            # should be 120
ls "$PBIP_REPO/data/PBIP/phage"  | wc -l            # should be 103
```

## 4. Run in-distribution evaluation (PBIP-on-PBIP)

```bash
source pbip.env

python scripts/run_pbip_inference.py \
    --phage_unirep_dir       "$PBIP_REPO/data/PBIP/phage" \
    --host_unirep_dir        "$PBIP_REPO/data/PBIP/host" \
    --model_h5               "$PBIP_REPO/model/dataset_PBIP/final_model.h5" \
    --interaction_matrix     "$CIPHER_VAL_GENOMES/PBIP/metadata/interaction_matrix.tsv" \
    --out_csv                "$PBIP_OUTPUT_ROOT/PBIP/prediction_scores.csv"
```

This produces a hosts × phages prediction matrix you can score with
cipher's HR@k pipeline.
