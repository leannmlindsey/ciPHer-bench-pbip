# Setup + reproduce

## Workflow at a glance

```text
1. (on laptop, ONCE) download PBIP's Google Drive contents
2. (on laptop) build data zip
3. (on laptop) rsync zip to Delta
4. (on Delta) unzip into data/
5. (on Delta) source pbip.env, build conda env, run wrapper
```

## 1. (Manual one-time step) — download the Google Drive contents

PBIP's upstream README points at this Drive folder for the trained
weights + pre-computed UniRep features + raw FASTAs:

  https://drive.google.com/drive/folders/1c1JNePxM5IFlTqt6CglUHWi-J-Z_1uoo

Download the six zips manually (browser, GDrive doesn't allow programmatic
folder downloads):
- `bac_faa.zip`
- `bac_fasta.zip`
- `data.zip`             ← UniRep features for 120 hosts + 103 phages
- `model.zip`            ← `final_model.h5` (~40 MB, Keras 2)
- `phage_faa.zip`
- `phage_fasta.zip`

Extract all six into a `PBIP/` directory on the laptop. The final layout:

```
.../pbip_run/PBIP/
├── data/PBIP/host/*.txt          (120 host UniRep 1900-d vectors)
├── data/PBIP/phage/*.txt         (103 phage UniRep 1900-d vectors)
├── model/dataset_PBIP/final_model.h5
├── bac_faa_2021/                  (raw bacterial AA FASTAs)
├── phage_faa_2021/                (raw phage AA FASTAs)
└── ...
```

## 2. Build the data zip

```bash
cd /Users/leannmlindsey/Desktop/ciPHer-bench-staging/ciPHer-bench-pbip
bash build_data_zip.sh
# Output: /Users/leannmlindsey/Desktop/ciPHer-bench-data-zips/ciPHer-bench-pbip-data.zip
```

Layout mirrors the laptop tree:
- `data/PBIP/` — upstream code + downloaded GDrive contents
- `data/cipher/data/validation_data/HOST_RANGE/PBIP/metadata/` — cipher's
  PBIP interaction matrix
- `data/cipher_val_genomes/PBIP/metadata/` — same file, accessible via
  `${CIPHER_VAL_GENOMES}/PBIP/metadata/`

## 3. Transfer + unzip on Delta

```bash
ZIP=/Users/leannmlindsey/Desktop/ciPHer-bench-data-zips/ciPHer-bench-pbip-data.zip
rsync -avz --info=progress2 "${ZIP}" \
    llindsey1@dt-login.delta.ncsa.illinois.edu:/projects/bfzj/llindsey1/PHI_TSP/ciPHer-comparisons/pbip/data/

ssh llindsey1@dt-login.delta.ncsa.illinois.edu
cd /projects/bfzj/llindsey1/PHI_TSP/ciPHer-comparisons/pbip

git clone git@github.com:LeAnnMLindsey/ciPHer-bench-pbip.git .   # first time
cd data && unzip -q ciPHer-bench-pbip-data.zip && cd ..
```

## 4. Build the conda env

```bash
module load anaconda3 2>/dev/null || true
eval "$(conda shell.bash hook)"
conda create -n pbip python=3.10 -y
conda activate pbip
pip install tensorflow tf-keras keras imbalanced-learn pandas scikit-learn biopython numpy
```

The `tf-keras` package provides the Keras 2 API even when TensorFlow 2.x
is installed — required because PBIP's `final_model.h5` was saved with
Keras 2. The wrapper sets `TF_USE_LEGACY_KERAS=1` to route Keras imports
through the shim.

## 5. Configure paths + run

```bash
cp config/pbip_delta.env pbip.env
source pbip.env

# Verify:
ls "${PBIP_REPO}/model/dataset_PBIP/final_model.h5"   # ~40 MB
ls "${PBIP_REPO}/data/PBIP/host"   | wc -l            # 120
ls "${PBIP_REPO}/data/PBIP/phage"  | wc -l            # 103

# Run in-distribution evaluation (PBIP-on-PBIP):
./scripts/run_pbip_on_pbip_dataset.sh
```

Output: `${PBIP_OUTPUT_ROOT}/PBIP/prediction_scores.csv` (hosts × phages
predicted lytic-interaction probability matrix).
