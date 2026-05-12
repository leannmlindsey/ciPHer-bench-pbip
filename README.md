# ciPHer-bench-pbip

Reproducible wrapper around **PBIP** (Ma et al. 2025,
*Briefings in Bioinformatics* DOI 10.1093/bib/bbaf656) for evaluation
on ciPHer's K. pneumoniae validation panel.

PBIP is a deep-learning model that takes 1900-d UniRep features from
phage and host proteins and predicts the lytic-interaction probability
via a CNN + BiGRU + attention head.

Upstream: https://github.com/a1678019300/PBIP

## What this repo contains

- `scripts/run_pbip_inference.py` — runs the pre-trained PBIP model
  on a (host_UniRep, phage_UniRep) directory pair against a cipher
  interaction matrix. Uses `tf-keras` (Keras 2 compatibility shim)
  because PBIP's `final_model.h5` was saved under Keras 2.
- `config/` — env-style config templates.

## What this repo does NOT contain

- PBIP upstream source (`git clone` upstream)
- The Google Drive download (~1.6 GB) — pre-computed UniRep features +
  trained model weights + raw FASTAs. See [SETUP.md](SETUP.md).

## Important caveat: in-distribution only

**PBIP's training matrix IS cipher's PBIP validation set.** The 120
hosts × 103 phages PBIP was trained on are the same panel cipher uses
to evaluate. So the number you get from this wrapper is
**in-distribution** — it's the upper bound on what PBIP can do on
exactly its training distribution.

To get an honest OOD evaluation of PBIP on cipher's other K. pneumoniae
sets (CHEN, GORODNICHIV, UCSD, Townsend, Jing, Wang), you would need
to (a) install the original UniRep code (Python 3.7 + TensorFlow 1.x),
(b) extract UniRep features for each new host/phage proteome, then
(c) run this wrapper. That's currently a known TODO; the wrapper here
only covers the in-distribution cell.

## Quick start

```bash
git clone https://github.com/LeAnnMLindsey/ciPHer-bench-pbip.git
cd ciPHer-bench-pbip

cp config/pbip.env.template pbip.env
pico pbip.env
source pbip.env

# See SETUP.md for the Google Drive download + tf-keras env install
python scripts/run_pbip_inference.py
```

See [SETUP.md](SETUP.md) for full setup.

## Citation

If you use this wrapper, please cite:
- Ma L, Gao P, Liu G, Bai Y, Lin Q, Li J, Xiao M. *PBIP: a deep learning
  framework for predicting phage-bacterium interactions at the strain
  level.* Briefings in Bioinformatics (2025).
  https://doi.org/10.1093/bib/bbaf656
- (manuscript in prep) ciPHer benchmarking paper.
