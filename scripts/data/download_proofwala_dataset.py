#!/usr/bin/env python3
"""Download the released ProofWalaDataset snapshot from Hugging Face.

This avoids requiring git-lfs or huggingface_hub. It uses the Hugging Face
tree API, stores the file manifest, downloads files from resolve URLs, and
verifies byte sizes from the manifest.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys
import time
import urllib.parse
import urllib.request


DEFAULT_REPO = "amitayusht/ProofWalaDataset"
DEFAULT_REVISION = "main"


def download_url(url: str, destination: pathlib.Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url) as response, destination.open("wb") as output:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            output.write(chunk)


def fetch_manifest(repo: str, revision: str, manifest_path: pathlib.Path) -> list[dict]:
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    api_url = (
        f"https://huggingface.co/api/datasets/{repo}/tree/"
        f"{urllib.parse.quote(revision)}?recursive=1"
    )
    download_url(api_url, manifest_path)
    with manifest_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def load_or_fetch_manifest(repo: str, revision: str, manifest_path: pathlib.Path) -> list[dict]:
    if manifest_path.exists():
        with manifest_path.open("r", encoding="utf-8") as handle:
            return json.load(handle)
    return fetch_manifest(repo, revision, manifest_path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--revision", default=DEFAULT_REVISION)
    parser.add_argument(
        "--output-dir",
        default="data/proofwala_dataset/ProofWalaDataset",
        help="Directory where the dataset snapshot should be written.",
    )
    parser.add_argument(
        "--manifest",
        default=".hf_cache/proofwala_dataset_tree.json",
        help="Cached Hugging Face tree API response.",
    )
    parser.add_argument("--retries", type=int, default=3)
    args = parser.parse_args()

    root = pathlib.Path(args.output_dir)
    manifest_path = pathlib.Path(args.manifest)
    rows = load_or_fetch_manifest(args.repo, args.revision, manifest_path)
    files = [row for row in rows if row.get("type") == "file"]
    total_bytes = sum(row.get("size", 0) for row in files)
    downloaded_bytes = 0
    started_at = time.time()
    base_url = f"https://huggingface.co/datasets/{args.repo}/resolve/{args.revision}/"

    print(f"files: {len(files)}")
    print(f"expected bytes: {total_bytes}")
    print(f"output: {root}")

    for index, row in enumerate(files, start=1):
        relative_path = row["path"]
        expected_size = row.get("size", 0)
        output_path = root / relative_path

        if output_path.exists() and output_path.stat().st_size == expected_size:
            downloaded_bytes += expected_size
            print(f"[{index}/{len(files)}] skip {relative_path}")
            continue

        url = base_url + urllib.parse.quote(relative_path)
        temp_path = output_path.with_name(output_path.name + ".tmp")

        for attempt in range(1, args.retries + 1):
            try:
                print(
                    f"[{index}/{len(files)}] download {relative_path} "
                    f"({expected_size} bytes), attempt {attempt}",
                    flush=True,
                )
                download_url(url, temp_path)
                actual_size = temp_path.stat().st_size
                if actual_size != expected_size:
                    raise RuntimeError(
                        f"size mismatch for {relative_path}: "
                        f"{actual_size} != {expected_size}"
                    )
                temp_path.replace(output_path)
                downloaded_bytes += expected_size
                break
            except Exception as exc:
                print(f"error: {exc}", file=sys.stderr, flush=True)
                if attempt == args.retries:
                    raise
                time.sleep(2 * attempt)

        elapsed_minutes = (time.time() - started_at) / 60
        print(
            f"progress: {downloaded_bytes / 1024 / 1024:.1f}/"
            f"{total_bytes / 1024 / 1024:.1f} MiB, "
            f"elapsed: {elapsed_minutes:.1f} min",
            flush=True,
        )

    print("download complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
