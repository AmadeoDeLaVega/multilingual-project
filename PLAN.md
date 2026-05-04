# PLAN

## Purpose

This document is a lean execution plan for a pilot research project on the question:

**Why does multilingual training improve theorem proving in ProofWala?**

The current plan uses the released [ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset) so we do **not** regenerate proof-step data with `itp-interface`. Because the team has three students with separate Nexus access, we train the three core models in parallel:

- E1: Lean-only baseline
- E3: real multilingual model
- E4: pseudo-multilingual control

Released ProofWala checkpoints remain useful as references, sanity checks, and fallback baselines, but the primary scientific comparison should use our three freshly trained checkpoints.

## Released Assets

Use these Hugging Face artifacts as first-class inputs and references:

- Dataset: [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset)
- Released Lean-only model reference: [amitayusht/ProofWala-Lean](https://huggingface.co/amitayusht/ProofWala-Lean)
- Released real multilingual model reference: [amitayusht/ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual)

The released models are CodeT5-base finetunes. Therefore E1, E3, and E4 should all start from `Salesforce/codet5-base`.

## Main Research Question

In a controlled pilot using the same dataset source and parallel Nexus training, is ProofWala's multilingual gain better explained by:

- genuine cross-system transfer from Lean + Coq training, or
- regularization from added non-Coq variation?

## Core Hypotheses

### H1. Structural Transfer Hypothesis

Lean and Coq share enough proof-state and tactic structure that joint training improves state-to-tactic modeling.

**Prediction:**

- E3 beats E1
- E3 beats E4

### H2. Regularization Hypothesis

The gain comes mostly from seeing more variation, which reduces overfitting to one syntax or repository style.

**Prediction:**

- E4 performs similarly to E3

### H3. Search-Calibration Hypothesis

The multilingual model helps mostly by producing better-ranked valid tactics during search, not necessarily by much better next-step exact prediction.

**Prediction:**

- gains are clearer in pass@k and compilable-tactic rate than in next-tactic accuracy
- E3 produces more compilable tactics per state and fewer early dead ends

## Minimal Final Experiment Set

These are the required experiments.

| ID | Name | Train? | Starting Model | Data | Assigned Work |
|---|---|---:|---|---|---|
| E0 | Released multilingual sanity-check | No | [ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual) | Small fixed eval | Verify environment and evaluation pipeline |
| E1 | Lean-only baseline | Yes | `Salesforce/codet5-base` | ProofWalaDataset `lean/train` | Student 1 |
| E3 | Real multilingual | Yes | `Salesforce/codet5-base` | Smoke: ProofWalaDataset `multilingual/train`; final: token-matched Lean+Coq mixture | Student 2 |
| E4 | Pseudo-multilingual | Yes | `Salesforce/codet5-base` | Lean train + synthetic Lean variant | Student 3 |

## Optional Stretch Goal

Only run this if E0, E1, E3, and E4 are complete early enough.

| ID | Name | Train? | Starting Model | Purpose |
|---|---|---:|---|---|
| E5a | Lean-to-CategoryTheory adaptation | Fine-tune | E1 checkpoint | Adaptation baseline |
| E5b | Multilingual-to-CategoryTheory adaptation | Fine-tune | E3 checkpoint | Adaptation treatment |

CategoryTheory adaptation is useful, but **not required** for the pilot to succeed.

## Why This Plan Is Feasible

The earlier risk was data generation. Full `itp-interface` extraction can take days. The Hugging Face dataset already provides proof-step records with standard splits, so we can train directly from it.

The other bottleneck was compute. The team has three Nexus accounts, so each student can train one model on one RTX A5000 job:

- Student 1 trains E1
- Student 2 trains E3
- Student 3 trains E4

If enough A5000 GPUs are available, the three trainings can run concurrently.

## Important Limitation

This is still a pilot. It may use reduced subsets or fixed max-step budgets to fit class-account storage and wall-time limits.

To keep the comparison clean:

- train E1, E3, and E4 from the same base model: `Salesforce/codet5-base`
- use the same tokenizer
- use the same prompt grammar and field order
- use the same training settings where possible
- use the same fixed Lean evaluation subset
- use identical proof-search budgets and decoding settings
- document any unavoidable budget or dataset-size mismatch explicitly

Released E1/E3 checkpoints can be evaluated as secondary references, but they should not replace the primary freshly trained E1/E3 checkpoints unless our training plan fails.

## Dataset Strategy

Use [amitayusht/ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset) rather than regenerating full data with `itp-interface`.

The dataset page describes these families:

- `lean/`
- `coq/`
- `GeoCoq/`
- `math-comp/`
- `multilingual/`

Each family includes `train/`, `test/`, and `eval/` splits. Each JSON file contains a top-level `training_data` list with proof-step records.

## Required Datasets

- **E1:** Lean training split
- **E3 smoke tests:** ProofWalaDataset `multilingual/train`
- **E3 final training:** explicitly constructed token-matched Lean+Coq mixture
- **E4:** Lean training split plus synthetic Lean augmentation
- **Evaluation:** one fixed Lean eval/test subset shared by E1, E3, and E4

## E3 Data Recommendation

Use a two-stage plan:

1. **Smoke tests:** use ProofWalaDataset `multilingual/train`.
2. **Final run:** construct an explicit token-matched Lean+Coq mixture.

The smoke-test goal is operational: make sure the config, loader, model, GPU memory, checkpointing, and logging work quickly.

The final-run goal is causal control. Build the final E3 mixture and record:

- Lean example count
- Coq example count
- estimated token count by source
- sampling rule
- target token budget
- how closely the mixture is token-matched to E1 and E4

If time is short or the token-matched mixture has a blocking implementation issue, fall back to `multilingual/train` for E3 final training and document that limitation explicitly.

## Hard Control Rule

For E1, E3, and E4, keep the following matched as closely as possible:

- base architecture: `Salesforce/codet5-base`
- tokenizer
- max sequence length
- prompt grammar and prompt field order
- number of optimization steps
- batch size policy
- gradient accumulation
- precision setting
- checkpoint cadence
- evaluation subset
- proof-search budget
- decoding settings
- metric scripts

Record for each run:

- total training examples used
- estimated total tokens
- number of optimization steps
- GPU type
- wall-clock time
- final checkpoint path

## Prompt-Format Rule

Do not treat prompt-format variation as the control.

ProofWala's multilingual setup uses a shared prompt format across Lean and Coq, so E1, E3, and E4 should keep the same prompt grammar and field order. The pseudo-multilingual transformation should change surface content, not the template.

## Important Implementation Note

The ProofWala-style configs often use `no_steps: True`, so the model is trained mostly from the current proof state rather than previous proof-step history.

This means E4 should focus on variation in serialized proof states and tactics, not on changing proof-history context.

## Split Discipline

Freeze all train, validation, and test subsets before full training starts.

Do not change the evaluation subset after training starts unless a blocking bug is found.

## Pseudo-Multilingual Data Design

E4 should be **simple, conservative, and meaning-preserving**.

E4 should be constructed as:

- original Lean training data
- plus synthetic Lean-variant augmentation

Do not replace the original Lean data with transformed-only data.

Recommended transformations on Lean data:

1. consistent variable renaming
2. harmless formatting changes that preserve serialized state and target tactic structure
3. consistent renaming of selected non-semantic local identifiers when safe
4. optional theorem-name anonymization or aliasing if theorem names are actually exposed in the chosen training records

### Final E4 Renaming Requirement

The Day 3 E4 smoke data may use a simple local-renaming transformation to test the training pipeline. That smoke transformation is **not sufficient** for final E4 training by itself.

For final E4, refine the renaming logic and audit it carefully. Lean identifiers can include primes, Unicode letters, generated names, inaccessible names, subscripts, and tactic-generated suffixes. A naive text replacement can accidentally:

- rename part of a theorem or namespace name
- miss related forms such as `x`, `x_1`, `x₁`, or `x'`
- create invalid Lean syntax
- rename a hypothesis in the state but fail to rename the same identifier in the target tactic
- rename identifiers inside string literals or notation-like fragments where replacement is unsafe

Use this safer final procedure:

1. Extract candidate local identifiers only from the serialized local context/hypothesis lines, not from global theorem names or namespace-qualified constants.
2. Exclude built-in names, keywords, namespaces, theorem names, constructors, tactics, and any identifier that appears only as part of a qualified name such as `Nat.add` or `CategoryTheory.Functor`.
3. Build one deterministic per-example rename map, for example `x -> pseudo_0`, `h -> pseudo_1`, using a fixed seed and preserving valid Lean identifier syntax.
4. Apply the same rename map to the serialized hypotheses, goals, and proof-step target.
5. Use token-boundary-aware replacement rather than plain substring replacement.
6. Record the rename map in `addition_state_info` for every transformed example.
7. Run an audit before full training:
   - inspect at least 50 examples manually
   - count examples with empty rename maps
   - count examples where the proof step changed
   - count examples where start goals changed
   - check that no transformed record is byte-identical to its source
   - sample long examples, Unicode-heavy examples, and examples with primes/subscripts
8. Prefer dropping a risky transformed example over keeping an aggressive or ambiguous rewrite.

The final E4 audit should be saved as `data/pseudo_multilingual/e4_audit.md` and should include examples of the original state, pseudo state, original tactic, pseudo tactic, and rename map.

Avoid transformations that:

- change semantics
- break parsing
- produce unnatural prompts
- require a second proof assistant
- change prompt grammar or reorder prompt sections

## Model Choice

Use `Salesforce/codet5-base` for E1, E3, and E4.

### Non-Negotiable Rules

- Do not train one experiment as CodeT5-small while the others use CodeT5-base.
- Do not initialize E4 from ProofWala-Multilingual.
- Do not include real Coq data in E4.
- Keep tokenizer and prompt grammar identical across E1, E3, and E4.

## Nexus Compute Plan

The verified Nexus class-account resources should be the first-choice compute target before renting external GPU instances.

Live checks on `nexusclass01.umiacs.umd.edu` showed:

- partition: `class`
- account: `class`
- accessible nodes: `tron[06-44,46-61]`
- `tron06-44`: RTX A4000, 16GB VRAM, 4 GPUs per node
- `tron46-61`: RTX A5000, 24GB VRAM, 8 GPUs per node
- confirmed GPU allocation: `NVIDIA RTX A5000`, `24564 MiB` VRAM, driver `590.48.01`

### Nexus QoS Limits

| QoS | Max wall time | Max per job |
|---|---:|---|
| `default` | 3 days | 4 CPU, 1 GPU, 32GB RAM |
| `medium` | 2 days | 8 CPU, 2 GPU, 64GB RAM |
| `high` | 1 day | 16 CPU, 4 GPU, 128GB RAM |

The class partition also has a concurrent per-user cap:

- 32 CPU cores
- 4 GPUs
- 256GB RAM

### Recommended Training Request

Each student should use one RTX A5000 job:

```bash
#SBATCH --partition=class
#SBATCH --account=class
#SBATCH --qos=medium
#SBATCH --gres=gpu:rtxa5000:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
```

Training should use:

- per-device batch size 1
- fp16 or bf16 where supported
- gradient checkpointing
- frequent checkpoint saves
- resume-from-checkpoint support
- reduced subset first, then scale after a successful calibration run

Use RTX A4000 only as a fallback for evaluation or very small training dry runs. Its 16GB VRAM is likely too tight for comfortable CodeT5-base training.

### Expected Training Time

Assuming `max_steps` around 5000, 2048-token context, batch size 1, fp16/bf16, and gradient checkpointing on one RTX A5000:

| Run | Expected Time |
|---|---:|
| E1 | 6-14 hours |
| E3 | 8-18 hours |
| E4 | 8-20 hours |

If all three students train concurrently and the queue has enough A5000s, training wall-clock is roughly 1 day. Budget 1-2 days including queue time, setup, calibration, and restarts.

Before full training, run a shared 100-step calibration. If 100 steps takes `T` minutes, estimate:

```text
5000-step time ~= T * 50
```

## Storage Constraint

Class accounts use `/fs/classhomes/<username>`, documented with a 30GB personal quota. Class accounts do not receive the normal Nexus network scratch allocation.

For this project:

- keep Hugging Face caches under explicit paths
- assume there is no shared class storage
- each student downloads/caches the needed ProofWalaDataset subset separately under their own `/fs/classhomes/<username>/multilingual-project`
- each student should download only the subset needed for their assigned run when possible
- use reduced dataset shards first
- keep only the latest few checkpoints
- clear failed-run checkpoints and stale caches
- request extra class project storage through the TA/instructor if needed

GitHub is for source code, configs, small manifests, notes, and small result summaries. It is not for datasets, checkpoints, model caches, or proof dumps.

If RTX A5000 training OOMs after memory-saving settings, or if storage becomes the blocker, rent an external 48GB GPU instance such as Lambda Cloud A6000.

## Metrics

The project should emphasize both model behavior and search behavior, but prioritize search diagnostics because that is where ProofWala gives the strongest clues.

## Primary Metrics

- `pass@1`
- `pass@5`
- compilable-tactic rate

## Secondary Metrics

- next-tactic top-k accuracy
- average valid tactics per state
- early dead-end rate
- proof tree node count
- proof tree edge count
- average branching factor
- average proof search time

## Success Criteria

The pilot succeeds if it clearly answers at least one of these:

1. Does E3 outperform E1 on the fixed Lean evaluation subset?
2. Does E3 outperform E4?
3. Do gains appear mainly in proof-search behavior rather than next-step accuracy?

## Interpretable Outcomes

### Outcome A

- E3 > E1
- E3 > E4

**Interpretation:** evidence consistent with genuine cross-system transfer.

### Outcome B

- E3 > E1
- E3 ~= E4

**Interpretation:** much of the gain may come from regularization and added variation.

### Outcome C

- E3 and E4 improve mainly on pass@k / compilable-tactic rate
- next-step gains are small

**Interpretation:** gains may be driven largely by better search calibration.

### Optional Outcome D

- E5b > E5a

**Interpretation:** multilingual pretraining helps low-resource adaptation to a new domain.

## Compute Philosophy

Use Nexus first. With three student accounts, E1, E3, and E4 can train in parallel on separate RTX A5000 jobs.

If Nexus compute is limited, reduce:

- dataset size
- training steps
- number of checkpoints
- beam width
- number of evaluation theorems

Do **not** weaken the causal structure before reducing scale. In particular, do not switch only one run to a smaller model.

## Risks and Mitigations

### Risk 1: Environment Setup Takes Too Long

**Mitigation:**
- run E0 on Day 1
- share one working environment recipe
- do not start full training until proof search works end to end

### Risk 2: Dataset Handling Takes Too Long

**Mitigation:**
- use ProofWalaDataset instead of regenerating with `itp-interface`
- start with reduced shards
- freeze a small but documented eval subset

### Risk 3: Training Does Not Finish

**Mitigation:**
- run a 100-step calibration first
- reduce training examples
- reduce total step count
- keep CodeT5-base for all runs
- use RTX A5000 with `medium` QoS
- checkpoint frequently and resume across jobs if needed

### Risk 3a: Training Exceeds RTX A5000 VRAM

**Mitigation:**
- use per-device batch size 1
- enable fp16/bf16 and gradient checkpointing
- reduce max sequence length only if necessary and document it
- fall back to external 48GB GPU if the main run cannot fit

### Risk 4: Search Evaluation Is Too Slow

**Mitigation:**
- first evaluate on a reduced fixed theorem subset
- only scale up after the main trend is visible

### Risk 5: E4 Transformation Is Too Aggressive

**Mitigation:**
- keep pseudo-multilingual changes minimal and reversible
- inspect a sample before training

### Risk 6: Class Storage Is Too Small

**Mitigation:**
- use reduced dataset shards
- limit checkpoint retention
- clear unused model/dataset caches
- ask the TA/instructor for class project storage if needed

## Day-by-Day Schedule

## Day 1: Environment Validation

### Tasks

- verify environment and dependencies
- run E0 with [ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual)
- confirm proof search, logs, and outputs work
- verify RTX A5000 allocation on each student account

### Deliverables

- one successful sanity-check run
- short environment note
- hardware note for each student account

### Exit Condition

Do not proceed until at least one proof search run completes successfully.

## Day 2: Dataset and Experiment Freeze

### Tasks

- each student downloads/caches their needed [ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset) subset separately
- verify available class storage in each student's `/fs/classhomes/<username>` directory
- set explicit per-account cache/checkpoint directories
- freeze the E1 Lean training subset
- freeze the E3 smoke-test source as ProofWalaDataset `multilingual/train`
- define the final E3 token-matched Lean+Coq mixture construction rule
- freeze the E4 Lean base subset
- freeze the Lean eval/test subset for E1, E3, and E4
- define the E4 pseudo-multilingual transformation
- confirm shared prompt grammar and field order
- estimate token counts for E1, E3, and E4
- define training budgets and checkpoint selection rules

### Deliverables

- dataset manifest
- split manifest
- E4 generation note
- token-budget note
- experiment table with student assignments

### Exit Condition

No further data-composition or evaluation-subset changes after Day 2 unless a blocking bug is found.

## Day 3: Calibration and Smoke Tests

### Tasks

- generate a small E4 sample
- manually inspect at least 50 transformed examples
- verify that E4 preserves semantics, prompt grammar, and parseability
- run E3 smoke test with `multilingual/train`
- build and validate the final E3 token-matched Lean+Coq mixture manifest
- run one 100-step calibration on RTX A5000
- estimate full-run time from calibration
- run short smoke tests for E1, E3, and E4
- confirm checkpoint saving and validation scripts

### Deliverables

- smoke-test logs
- E4 sample inspection note
- E3 token-matched mixture manifest
- calibration timing note
- final training commands
- final evaluation command templates

## Days 4-5: Parallel Training

### Tasks

- Student 1 trains E1 from `Salesforce/codet5-base`
- Student 2 trains E3 from `Salesforce/codet5-base`
- Student 3 trains E4 from `Salesforce/codet5-base`
- all use Nexus `class` / `medium` / `gpu:rtxa5000:1`
- monitor training and validation
- record throughput and wall-clock time
- record final training steps, examples, estimated token budget, and checkpoint path

### Deliverables

- E1 checkpoint and training summary
- E3 checkpoint and training summary
- E4 checkpoint and training summary

## Days 6-7: Base Evaluation

### Tasks

- evaluate trained E1
- evaluate trained E3
- evaluate trained E4
- optionally evaluate released ProofWala-Lean and ProofWala-Multilingual as references
- use the same fixed Lean subset and proof-search budget for all models
- compute pass@1, pass@5, and compilable-tactic rate

### Deliverables

- main comparison table
- optional released-checkpoint reference table
- first interpretation note
- checkpoint/model inventory

### Exit Condition

You should know whether E3 beats E1, and whether E4 is close to or far from E3.

## Days 8-10: Search Diagnostics and Analysis

### Tasks

- collect proof tree statistics
- compute valid tactics per state
- compute early dead-end rate
- compare search-time behavior
- compare results against the token-budget note before drawing conclusions
- prepare plots and clean tables

### Deliverables

- search diagnostics table
- 2 to 4 core figures

## Optional Days 11-12: CategoryTheory Adaptation

Run this only if the core experiments are already complete and stable.

### Tasks

- fine-tune E1 on CategoryTheory to create E5a
- fine-tune E3 on CategoryTheory to create E5b
- evaluate both on the same held-out split

### Deliverables

- E5a checkpoint
- E5b checkpoint
- adaptation results table

## Day 13: Report Drafting

### Recommended Report Structure

1. research question
2. released dataset used
3. Nexus parallel training setup
4. experiment matrix and limitations
5. E4 construction and token-budget note
6. results
7. search diagnostics
8. interpretation
9. limitations
10. optional adaptation results, if run

### Deliverables

- 3 to 5 page memo
- figures inserted
- short conclusion per hypothesis

## Day 14: Packaging and Reproducibility

### Tasks

- archive configs
- archive split definitions
- archive commands
- archive checkpoint inventory
- archive released asset links and revisions
- archive final figures and tables

### Deliverables

- reproducibility appendix or folder
- final project summary
- one-slide or one-page summary

## Deliverables Checklist

### Required

- E0 sanity-check output
- E1 checkpoint and training summary
- E3 checkpoint and training summary
- E4 checkpoint and training summary
- frozen dataset manifest
- frozen split manifest
- token-budget note
- E4 generation and audit note
- base results table
- search diagnostics table
- 3 to 5 figures
- short internal memo
- reproducibility notes

### Optional

- released checkpoint reference evaluation
- E5a checkpoint
- E5b checkpoint
- adaptation results table
- adaptation figure

## Recommended Figures

### Required Figures

1. training and validation loss curves for E1, E3, and E4
2. pass@1 and pass@5 comparison chart for E1, E3, E4
3. compilable-tactic rate comparison for E1, E3, E4
4. search-diagnostics chart such as branching factor or early dead-end rate

### Optional Figure

5. adaptation comparison for E5a vs E5b

## Interpretation Template

### Claim 1: Does multilingual training help in our retrained setup?

Answer with:

- E3 vs E1

### Claim 2: Is the multilingual effect more than regularization?

Answer with:

- E3 vs E4

### Claim 3: Does multilingual training mainly improve search calibration?

Answer with:

- pass@k differences
- compilable-tactic rate differences
- next-step metric differences
- dead-end / branching differences

### Optional Claim 4: Does multilingual pretraining help domain adaptation?

Answer with:

- E5b vs E5a

## What Not to Overclaim

This pilot can support statements such as:

- "In our controlled pilot, E3 outperformed E1 on our fixed evaluation subset."
- "Our pseudo-multilingual E4 did or did not close the gap to real multilingual training."
- "The multilingual gain appears partly attributable to improved compilable-tactic generation or search behavior."

This pilot should not support statements such as:

- "We have fully explained why multilingual theorem proving works."
- "The mechanism is definitively structural transfer in all settings."
- "The result generalizes universally across all theorem provers and model families."

## Recommended Next Step After This Pilot

If the pilot is successful, the next project should add:

- more than one random seed
- tighter token-matched controls
- more than one pseudo-multilingual transformation scheme
- stronger representation analysis
- explicit Lean/Coq theorem-pair or proof-state alignment
- broader domain adaptation
