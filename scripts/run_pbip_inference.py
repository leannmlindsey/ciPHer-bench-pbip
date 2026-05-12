"""Run PBIP (Ma et al. 2025) inference on a cipher validation dataset.

For each (phage, host) pair, load pre-computed 1900-d UniRep features and run
the bundled PBIP CNN+BiGRU+Attention model (final_model.h5) to predict
the lytic-interaction probability.

NOTE: PBIP's training set IS cipher's PBIP validation set (same RCIP phages
+ KP host panel from Ma et al. 2025 Brief Bioinform). PBIP-on-cipher-PBIP is
in-distribution; for OOD evaluation we need UniRep features on cipher's
other datasets (which requires installing UniRep — see README).
"""
import os
os.environ["TF_USE_LEGACY_KERAS"] = "1"
os.environ["CUDA_VISIBLE_DEVICES"] = ""

import argparse, csv
from pathlib import Path
import numpy as np
import pandas as pd
import tf_keras as keras
from sklearn.preprocessing import StandardScaler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--phage_unirep_dir", required=True)
    ap.add_argument("--host_unirep_dir", required=True)
    ap.add_argument("--model_h5", required=True)
    ap.add_argument("--interaction_matrix", required=True,
                    help="cipher dataset interaction_matrix.tsv (host_id, host_assembly, ..., phage_id, label)")
    ap.add_argument("--out_csv", required=True, help="output: hosts × phages prediction matrix")
    ap.add_argument("--file_suffix", default=".txt")
    args = ap.parse_args()

    print("[1] Load interaction matrix", flush=True)
    pairs = []
    phages, hosts = set(), set()
    for r in csv.DictReader(open(args.interaction_matrix), delimiter="\t"):
        pairs.append((r["phage_id"], r["host_id"]))
        phages.add(r["phage_id"]); hosts.add(r["host_id"])
    print(f"  {len(pairs)} pairs, {len(phages)} phages, {len(hosts)} hosts")

    print("\n[2] Load UniRep features", flush=True)
    phage_feat = {}
    for p in sorted(phages):
        f = Path(args.phage_unirep_dir)/f"{p}{args.file_suffix}"
        if f.exists():
            phage_feat[p] = np.loadtxt(f).astype(np.float32)
    host_feat = {}
    for h in sorted(hosts):
        f = Path(args.host_unirep_dir)/f"{h}{args.file_suffix}"
        if f.exists():
            host_feat[h] = np.loadtxt(f).astype(np.float32)
    print(f"  phages with features: {len(phage_feat)}/{len(phages)}")
    print(f"  hosts  with features: {len(host_feat)}/{len(hosts)}")

    print("\n[3] Load model", flush=True)
    model = keras.models.load_model(args.model_h5)
    print(f"  loaded, n_params: {model.count_params()}")

    print("\n[4] Build feature batches + predict", flush=True)
    valid_pairs = [(p, h) for p, h in pairs if p in phage_feat and h in host_feat]
    if len(valid_pairs) < len(pairs):
        print(f"  WARNING: skipping {len(pairs)-len(valid_pairs)} pairs (missing UniRep features)")

    X_p = np.stack([phage_feat[p] for p, _ in valid_pairs])
    X_h = np.stack([host_feat[h] for _, h in valid_pairs])

    # PBIP's training script standardizes features per fold — here we just predict
    # with the raw features (model has its own normalization layers).
    preds = model.predict([X_p, X_h], batch_size=32, verbose=1).flatten()

    df = pd.DataFrame({"phage_id": [p for p, _ in valid_pairs],
                       "host_id":  [h for _, h in valid_pairs],
                       "predicted_p_lysed": preds})
    pivot = df.pivot(index="host_id", columns="phage_id", values="predicted_p_lysed")
    Path(args.out_csv).parent.mkdir(parents=True, exist_ok=True)
    pivot.to_csv(args.out_csv)
    print(f"  -> {args.out_csv}  shape {pivot.shape}")
    print(f"  scores  min={pivot.values.min():.4f}  max={pivot.values.max():.4f}  mean={pivot.values.mean():.4f}")


if __name__ == "__main__":
    main()
