# PBIP Delta data manifest

## Required: upstream PBIP + Google Drive download (1.6 GB)

PBIP's training weights + pre-computed UniRep features live in a Google
Drive folder linked from the upstream README, NOT in their GitHub repo.

```bash
# On laptop (because Google Drive web downloads are easiest there):
# Download the 6 zips from
#   https://drive.google.com/drive/folders/1c1JNePxM5IFlTqt6CglUHWi-J-Z_1uoo
# Extract them under a single PBIP/ directory so the layout matches
# what scripts/run_pbip_on_pbip_dataset.sh expects:
#   PBIP/data/PBIP/host/*.txt   (120 host UniRep 1900-d vectors)
#   PBIP/data/PBIP/phage/*.txt  (103 phage UniRep 1900-d vectors)
#   PBIP/model/dataset_PBIP/final_model.h5  (~40 MB Keras 2 model)
#   PBIP/bac_faa_2021/   PBIP/phage_faa_2021/   (raw amino acid FASTAs)

# Then rsync up to Delta:
rsync -avz --info=progress2 \
    /Users/leannmlindsey/WORK/CLAUDE_DPOTROPISEARCH/claude_copy/DpoTropiSearch/benchmark_external/pbip_run/PBIP/ \
    llindsey1@dt-login.delta.ncsa.illinois.edu:/projects/bfzj/llindsey1/PHI_TSP/ciPHer-comparisons/pbip/PBIP/
```

## Required: cipher's PBIP interaction matrix (already on Delta)

`${CIPHER_REPO}/data/validation_data/HOST_RANGE/PBIP/metadata/interaction_matrix.tsv`
is part of cipher itself — already on Delta at the canonical
`/projects/bfzj/llindsey1/PHI_TSP/ciPHer/data/...` location.

## Wrapping note: PBIP is in-distribution only (current scope)

The wrapper runs PBIP on PBIP's own training matrix → in-distribution
result. An OOD evaluation (PBIP on cipher's other K. pneumoniae sets)
would require running the original UniRep (Python 3.7 + TF 1.x — see
upstream PBIP repo) to extract 1900-d features for each new
host/phage proteome. That's a separate workstream and not handled here.

## SLURM template

PBIP's inference is fast (~minutes) and CPU-only (the Keras model runs
on CPU per the `CUDA_VISIBLE_DEVICES=""` line in run_pbip_inference.py).
A small CPU job is sufficient — no GPU needed.

```bash
#SBATCH --account=bfzj-delta-cpu          # confirm with allocations
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=00:30:00

source $(conda info --base)/etc/profile.d/conda.sh
conda activate ${PBIP_CONDA_ENV}
source pbip.env

./scripts/run_pbip_on_pbip_dataset.sh
```

If you don't have a Delta CPU allocation, use the GPU partition
(`bfzj-dtai-gh` / `ghx4`) — the GPU will sit idle but the job will run.
