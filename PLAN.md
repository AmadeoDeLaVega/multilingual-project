# PLAN

## Finalized Project Status

This project is complete for the CMSC848T final report.  The original goal was
to test why multilingual training improves ProofWala-style theorem proving.  The
final pilot does not find one universal mechanism.  Instead, the result depends
on the evaluation benchmark:

- **Easy_Lean:** E4 is strongest.  This supports the regularization hypothesis:
  meaning-preserving syntax variation can strongly help on Lean-like theorem
  patterns.
- **Hard_Lean:** E3 is strongest.  This supports the cross-language-transfer
  hypothesis on harder external theorem styles.

The final report should therefore frame the project as evidence for a
distribution-dependent mechanism: syntax variation matters most on Easy_Lean,
while real multilingual Lean+Rocq training matters most on Hard_Lean.

## Research Question

Why does multilingual training improve theorem proving in ProofWala?

We test two main hypotheses:

- **H1: Cross-language transfer.**  A model trained on Lean and Rocq may learn
  proof-state transition patterns that transfer across proof assistants.
- **H2: Regularization from syntax variation.**  A model exposed to more varied
  syntax may avoid overfitting to Lean-specific patterns and learn more robust
  tactic behavior.

E4 is the key control because it adds Lean syntax variation without adding real
Rocq tactics, libraries, or proof states.

## Released Assets

The project uses these released Hugging Face assets:

- Dataset: [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset)
- Lean reference model: [amitayusht/ProofWala-Lean](https://huggingface.co/amitayusht/ProofWala-Lean)
- Multilingual reference model: [amitayusht/ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual)

The released reference models are CodeT5-base finetunes.  Our controlled E1,
E3, and E4 models all use `Salesforce/codet5-small` because Nexus class-account
GPU memory and storage made CodeT5-small the safer common base.

## Final Experiment Matrix

| ID | Name | Base model | Training data | Purpose |
|---|---|---|---|---|
| E0 | Released-model sanity check | ProofWala-Multilingual | none | Verify environment and proof-search pipeline. |
| E1 | Lean-only baseline | `Salesforce/codet5-small` | ProofWalaDataset Lean split | Monolingual baseline. |
| E3 | Real multilingual | `Salesforce/codet5-small` | ProofWalaDataset multilingual-compatible Lean+Rocq split | Test real cross-system transfer. |
| E4 | Pseudo-multilingual control | `Salesforce/codet5-small` | Lean data plus synthetic Lean variants | Test whether syntax variation alone explains gains. |

All trainable models use the same base model, tokenizer, prompt grammar, and
proof-search pipeline where feasible.

## Final Training Runs

The final E1, E3, and E4 models were trained on Nexus with continuous
approximately 12-hour runs.  Earlier 5000-step smoke and staged runs were useful
for debugging but are not the main reported results.

Final model directories:

```text
runs/E1/model/pilot-e1-lean-only-34000x1/final
runs/E3/model/pilot-e3-real-multilingual/final
runs/E4/model/pilot-e4-pseudo-multilingual/final
```

Training used:

- one NVIDIA RTX A5000 GPU per run
- Nexus `class` partition and `medium` QoS
- `Salesforce/codet5-small`
- checkpoint retention reduced to control storage pressure
- final model validation with `model.safetensors`

## Final Benchmark Names

The final report and presentation use these benchmark names:

- **Easy_Lean:** the controlled Lean 4 benchmark built for this project.
- **Hard_Lean:** the combined miniF2F-derived external Lean benchmark.

The repository still contains internal file and script names with `core_eval`
and `minif2f` because those names were used during implementation.  They map to
the final names as follows:

| Final name | Internal source/config names | Meaning |
|---|---|---|
| Easy_Lean | `CoreEval.lean`, `core_eval_250.yaml`, `eval_core_eval_250.yaml`, `proof_search_core_eval.sbatch` | Controlled Lean 4 benchmark with 250 theorem declarations. |
| Hard_Lean | `miniF2F`, `proof_search_minif2f_easy10.sbatch`, `proof_search_minif2f_remaining_9h20.sbatch` | Combined external miniF2F-derived benchmark. |

## Easy_Lean Construction

Easy_Lean was built because the original external benchmark routes were hard to
run reliably on Nexus.  LeanDojo/mathlib introduced heavy build/runtime issues,
and the cloned miniF2F source is Lean 3 while the most reliable ProofWala path in
this project is Lean 4.

Easy_Lean was constructed by:

1. Starting from the lightweight Lean 4 project under
   `proof-wala/src/proof_wala/data/proofs/lean/lean4_proj`.
2. Adding `Lean4Proj/CoreEval.lean` with exactly 250 theorem declarations.
3. Using Lean-core theorem families covering propositional logic, equality,
   natural-number identities, lists, pairs, options, booleans, and some
   induction-shaped statements.
4. Keeping theorem bodies as `sorry` so proof search sees open goals.
5. Running all E1/E3/E4 models with the same theorem order, proof-search budget,
   decoding settings, and Lean environment.

The main Nexus run was:

```text
runs/proof_search_core_eval/6848604
```

## Hard_Lean Construction

Hard_Lean combines two miniF2F-derived runs:

```text
runs/proof_search_minif2f_easy10/6849079
runs/proof_search_minif2f_remaining_9h20/6850148
```

The easy-10 subset was deterministic and excluded from the later remaining-set
run.  The combined benchmark is harder and more external than Easy_Lean, so it
is used to test whether conclusions from Easy_Lean generalize.

## Final Results

| Benchmark | Model | Attempted | Proved | Pass rate | Intersection proved | Intersection pass rate |
|---|---|---:|---:|---:|---:|---:|
| Easy_Lean | E1 | 127 | 49 | 38.6% | 49 | 38.6% |
| Easy_Lean | E3 | 141 | 43 | 30.5% | 39 | 30.7% |
| Easy_Lean | E4 | 198 | 126 | 63.6% | 78 | 61.4% |
| Hard_Lean | E1 | 77 | 2 | 2.6% | 2 | 2.6% |
| Hard_Lean | E3 | 81 | 4 | 4.9% | 4 | 5.2% |
| Hard_Lean | E4 | 87 | 3 | 3.4% | 3 | 3.9% |

Easy_Lean was surprising because ProofWala suggests that real multilingual
training should improve over a Lean-only baseline, but E3 was below E1 on this
benchmark.  E4 also improved by a very large margin.  This supports H2, but the
size of the E4 gain is not fully understood and needs more research.

Hard_Lean gives the opposite ordering: E3 is strongest, while E1 and E4 are
closer.  This supports the concern that Easy_Lean is favorable to E4 and that
real multilingual training may matter more for harder external theorem styles.

## Search Diagnostics

The project reports proof-search behavior in addition to pass rate:

- valid tactics per proof state
- accepted tactic rate
- early dead-end rate
- proof-tree size
- branching factor
- average search time

These diagnostics are reported separately for Easy_Lean and Hard_Lean in:

```text
runs/analysis/day8_10/tables/
```

## Hard_Lean Proved Theorems

| Model | Proved theorem | Time | Proof tactic |
|---|---:|---:|---|
| E1 | `mathd_numbertheory_342` | 122.1s | `norm_num1` |
| E1 | `mathd_algebra_176` | 57.4s | `ring` |
| E3 | `amc12b_2020_p2` | 114.8s | `ring1` |
| E3 | `mathd_numbertheory_207` | 100.7s | `norm_num` |
| E3 | `mathd_algebra_329` | 68.6s | `linarith` |
| E3 | `mathd_algebra_176` | 85.7s | `ring` |
| E4 | `mathd_numbertheory_207` | 114.6s | `ring` |
| E4 | `mathd_algebra_176` | 86.2s | `ring1` |
| E4 | `mathd_numbertheory_175` | 92.1s | `norm_num` |

Overlap:

- All three models proved `mathd_algebra_176`.
- E3 and E4 both proved `mathd_numbertheory_207`.
- E1 uniquely proved `mathd_numbertheory_342`.
- E3 uniquely proved `amc12b_2020_p2` and `mathd_algebra_329`.
- E4 uniquely proved `mathd_numbertheory_175`.

## Main Challenges Overcome

- **Nexus storage pressure:** model checkpoints, Hugging Face caches, and proof
  dumps repeatedly pushed the class-home quota.  We reduced checkpoint retention,
  used `save_only_model` where appropriate, pruned failed checkpoints, and copied
  reusable artifacts off Nexus.
- **Training under wall-time limits:** early smoke runs were too weak for final
  conclusions, so the final comparison used longer continuous E1/E3/E4 runs.
- **Proof-search debugging:** the pipeline required model validation, Lean
  environment checks, tactic-parser fixes, Ray/runtime debugging, and incremental
  result logging.
- **Benchmark instability:** external benchmarks were difficult to run directly
  in the available setup, so Easy_Lean was created as a reliable controlled Lean
  4 benchmark and Hard_Lean was used as the external check.
- **E4 data quality:** the pseudo-Lean transformation was conservative and
  audited, but still needs further refinement before it can be treated as a
  perfect causal control.

## Reproducibility Entry Points

Use `README.md` for exact commands.  The key scripts are:

```text
scripts/nexus/download_proofwala_dataset.sbatch
scripts/nexus/train_e1.sbatch
scripts/nexus/train_e3.sbatch
scripts/nexus/train_e4.sbatch
scripts/nexus/proof_search_core_eval.sbatch
scripts/nexus/proof_search_minif2f_easy10.sbatch
scripts/nexus/proof_search_minif2f_remaining_9h20.sbatch
scripts/eval/build_day8_10_deliverables.py
```

The final local analysis artifacts are:

```text
runs/analysis/day8_10/internal_memo.md
runs/analysis/day8_10/analysis_payload.json
runs/analysis/day8_10/tables/
runs/analysis/day8_10/figures/
```

## What Not To Overclaim

This pilot supports:

- E4 is strongest on Easy_Lean.
- E3 is strongest on Hard_Lean.
- The mechanism behind multilingual gains appears distribution-dependent.
- Syntax variation and cross-language transfer may both matter, but on different
  theorem distributions.

This pilot does not prove:

- that multilingual theorem proving is fully explained;
- that E4 is a perfect causal control;
- that the results generalize to all theorem provers, all model sizes, or all
  Lean/Rocq theorem distributions;
- that the final E3 run is a perfectly token-matched Lean+Rocq comparison.

## Recommended Future Work

- Run more than one random seed.
- Build a cleaner token-matched Lean+Rocq mixture for E3.
- Improve and audit the E4 pseudo-Lean transformation.
- Evaluate on larger and more standard Lean benchmarks.
- Compare against the released ProofWala Lean and multilingual checkpoints.
- Analyze proof-state representations directly to test cross-language transfer.
