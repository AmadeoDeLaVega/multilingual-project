# PLAN

## Purpose

This document is a lean 2-week execution plan for a pilot research project on the question:

**Why does multilingual training improve theorem proving in ProofWala?**

The goal is not to fully reproduce the ProofWala paper. The goal is to run a **small causal pilot** that distinguishes between two main explanations:

1. **real cross-system transfer** from training on Lean and Coq together
2. **regularization from extra variation** without a real second proof assistant

This version of the plan is intentionally narrower so it can realistically finish in two weeks.

## Main Research Question

In a controlled pilot, is ProofWala's multilingual gain better explained by:

- genuine cross-system transfer, or
- regularization from added variation?

## Core Hypotheses

### H1. Structural transfer hypothesis

Lean and Coq share enough proof-state and tactic structure that joint training improves state-to-tactic modeling.

**Prediction:**
- real multilingual training beats monolingual training
- real multilingual training also beats pseudo-multilingual training

### H2. Regularization hypothesis

The gain comes mostly from seeing more variation, which reduces overfitting to one syntax or repository style.

**Prediction:**
- pseudo-multilingual training performs similarly to real multilingual training

### H3. Search-calibration hypothesis

The multilingual model helps mostly by producing better-ranked valid tactics during search, not necessarily by much better next-step exact prediction.

**Prediction:**
- gains are clearer in pass@k and compilable-tactic rate than in next-tactic accuracy
- multilingual models produce more compilable tactics per state and fewer early dead ends

## Minimal Final Experiment Set

These are the only required experiments.

| ID | Name | Train? | Data | Purpose |
|---|---|---:|---|---|
| E0 | Released multilingual sanity-check | No | Existing released model | Verify environment and evaluation pipeline |
| E1 | Lean-only baseline | Yes | Lean train split only | Monolingual baseline |
| E3 | Real multilingual | Yes | Lean + Coq mixed data | Main treatment |
| E4 | Pseudo-multilingual | Yes | Lean + synthetic Lean variant | Control for regularization and surface variation |

## Optional Stretch Goal

Only run this if E0, E1, E3, and E4 are complete early enough.

| ID | Name | Train? | Data | Purpose |
|---|---|---:|---|---|
| E5a | Lean-to-CategoryTheory adaptation | Fine-tune | CategoryTheory subset starting from E1 | Adaptation baseline |
| E5b | Multilingual-to-CategoryTheory adaptation | Fine-tune | CategoryTheory subset starting from E3 | Adaptation treatment |

CategoryTheory adaptation is useful, but **not required** for the pilot to succeed.

## Why This Reduced Plan Is Better

This plan keeps the most decision-critical comparison:

- **E1 vs E3 vs E4**

That is enough to answer:

1. does multilingual training help in a controlled pilot?
2. is the gain more than simple added variation?
3. does the gain mostly appear in search behavior?

This reduced plan is better suited to a 2-week schedule than training many baselines and adaptation runs by default.

## Dataset Strategy

## Recommended setup

Use existing extracted ProofWala-style proof-step data if available. Do not spend the project rebuilding extraction unless absolutely necessary.

### Required datasets

- **Lean training/eval data** for E1, E3, E4
- **Coq training data** for E3 only
- **CategoryTheory subset** only if optional E5 is attempted

## Hard control rule

For E1, E3, and E4, keep the following matched as closely as possible:

- total training tokens
- number of optimization steps
- model architecture
- tokenizer
- prompt grammar and prompt field order
- batch size policy
- evaluation subset
- proof-search budget

This is essential. Without it, the study may only show that more data helps.

## Prompt-format rule

Do not treat prompt-format variation as the control.

ProofWala's multilingual setup is built around a shared prompt format across Lean and Coq, so E1, E3, and E4 should use the same prompt grammar unless prompt variation itself becomes a separate experiment.

## Important implementation note

The ProofWala paper-style configs use `no_steps: True`, so the model is trained mostly from the current proof state rather than previous proof-step history.

This means the pilot should focus its controls on variation in serialized proof states and tactics, not on changing proof-history context.

## Split discipline

Freeze all train, validation, and test splits before training starts.

Do not change splits after Day 2 unless a blocking bug is found.

## Pseudo-multilingual data design

E4 should be **simple, conservative, and meaning-preserving**.

E4 should be constructed as:

- original Lean training data
- plus synthetic Lean-variant augmentation

Do not replace the original Lean data with transformed-only data. The closest control to real multilingual training is "same Lean base data, plus extra non-Coq variation."

Recommended transformations on Lean data:

1. consistent variable renaming
2. harmless formatting changes that preserve the serialized state and target tactic structure
3. consistent renaming of selected identifiers when safe
4. optional theorem-name anonymization or aliasing if theorem names are actually exposed in the chosen training records

Avoid transformations that:

- change semantics
- break parsing
- produce unnatural prompts
- require a second proof assistant
- change the prompt grammar or reorder prompt sections

The purpose of E4 is to add surface variation without adding true cross-system structure.

### Recommended E4 principle

If a transformation mostly changes metadata that the model does not actually consume, it is not a useful control.

Prioritize transformations that affect the proof state or tactic text seen by the model while remaining fully valid and natural.

## Model Choice

Use one ProofWala-compatible sequence-to-sequence model for all required experiments.

Recommended:

- `CodeT5-small`, or
- `CodeT5-base` with a reduced training budget

### Non-negotiable rule

Use the **same architecture and tokenizer** for E1, E3, and E4.

## Metrics

The project should emphasize both model behavior and search behavior, but prioritize search diagnostics because that is where ProofWala gives the strongest clues.

## Primary metrics

- `pass@1`
- `pass@5`
- compilable-tactic rate

## Secondary metrics

- next-tactic top-k accuracy
- average valid tactics per state
- early dead-end rate
- proof tree node count
- proof tree edge count
- average branching factor
- average proof search time

## Why these metrics

If E3 improves mainly on search metrics but not much on next-step accuracy, that supports the idea that multilingual training improves **search calibration** more than raw step prediction.

## Success Criteria

The pilot succeeds if it clearly answers at least one of these:

1. Does E3 outperform E1 in the controlled pilot?
2. Does E3 outperform E4 under matched budget?
3. Do gains appear mainly in proof-search behavior rather than next-step accuracy?

## Interpretable outcomes

### Outcome A
- E3 > E1
- E3 > E4

**Interpretation:** evidence for genuine cross-system transfer

### Outcome B
- E3 > E1
- E3 ~= E4

**Interpretation:** much of the gain may come from regularization and added variation

### Outcome C
- E3 and E4 improve mainly on pass@k / compilable-tactic rate
- next-step gains are small

**Interpretation:** gains may be driven largely by better search calibration

### Optional Outcome D
- E5b > E5a

**Interpretation:** multilingual pretraining helps low-resource adaptation to a new domain

## Compute Philosophy

If compute is limited, reduce:

- dataset size
- number of checkpoints
- beam width
- number of evaluation theorems

Do **not** weaken the causal structure before reducing scale.

The key comparison is more important than large absolute numbers.

## Risks and Mitigations

### Risk 1: Environment setup takes too long

**Mitigation:**
- run E0 on Day 1
- do not start training until one proof search run works end-to-end

### Risk 2: Data extraction takes too long

**Mitigation:**
- reuse existing extracted data
- if needed, reduce benchmark scope rather than expanding engineering work

### Risk 3: Training does not finish in time

**Mitigation:**
- reduce data size
- reduce total step count
- use a smaller compatible model

### Risk 4: Search evaluation is too slow

**Mitigation:**
- first evaluate on a reduced fixed theorem subset
- only scale up after the main trend is visible

### Risk 5: E4 transformation is too aggressive

**Mitigation:**
- keep pseudo-multilingual changes minimal and reversible
- inspect a sample before training

## Day-by-Day Schedule

## Day 1: Environment validation

### Tasks
- verify environment and dependencies
- run E0 with a released multilingual checkpoint
- confirm proof search, logs, and outputs work

### Deliverables
- one successful sanity-check run
- short environment note

### Exit condition
Do not proceed until at least one proof search run completes successfully.

## Day 2: Data freeze and experiment freeze

### Tasks
- freeze Lean split for E1
- freeze Coq subset for E3
- define E3 mixed data as Lean base plus Coq augmentation
- define E4 pseudo-multilingual augmentation as Lean base plus synthetic Lean augmentation
- freeze the prompt grammar and confirm that E1, E3, and E4 use the same prompt field order
- freeze evaluation subset
- estimate token counts for the Lean base, Coq augmentation, and synthetic Lean augmentation
- choose the token-matching and step-matching rule that will be used for all runs

### Deliverables
- dataset manifest
- split manifest
- E4 generation note
- token-budget note
- experiment table

### Exit condition
No further data-composition or budget-rule changes after Day 2 unless a blocking bug is found.

## Day 3: Smoke tests

### Tasks
- generate a small E4 sample and manually inspect it
- verify that E4 preserves semantics, prompt grammar, and parseability
- run token counts again after E4 generation
- short dry runs for E1, E3, E4 under the matched-budget rule
- confirm checkpoint saving
- confirm validation and metric scripts work
- confirm that the configured number of optimization steps is actually matched across runs

### Deliverables
- smoke-test logs
- E4 sample inspection note
- final command templates
- final hyperparameter sheet

## Days 4-5: Train E1

### Tasks
- launch Lean-only baseline
- monitor training and validation
- record throughput and wall-clock time
- record the actual token and step budget consumed so E3 and E4 can be matched to it

### Deliverables
- E1 checkpoint
- training summary
- E1 budget summary

## Days 6-7: Train E3 and E4

### Tasks
- finalize the E4 augmentation size to match the chosen E3 budget
- launch real multilingual training
- launch pseudo-multilingual training
- compare training behavior to E1
- inspect E4 data quality if anything looks suspicious
- verify that E3 and E4 remain matched to E1 on the planned control dimensions
- log any unavoidable budget mismatch explicitly

### Deliverables
- E3 checkpoint
- E4 checkpoint
- training summaries
- E3/E4 budget summary

## Day 8: Base evaluation

### Tasks
- evaluate E1, E3, E4 on next-tactic metrics
- evaluate compilable-tactic rate
- run proof search on a fixed reduced subset
- compute pass@1 and pass@5

### Deliverables
- main comparison table
- first interpretation note

### Exit condition
You should know whether E3 beats E1, and whether E4 is close to or far from E3.

## Days 9-10: Search diagnostics and analysis

### Tasks
- collect proof tree statistics
- compute valid tactics per state
- compute early dead-end rate
- compare search-time behavior
- compare results against the matched-budget notes before drawing conclusions
- prepare plots and clean tables

### Deliverables
- search diagnostics table
- 2 to 4 core figures

## Optional Days 11-12: CategoryTheory adaptation

Run this only if the core experiments are already complete and stable.

### Tasks
- fine-tune E1 on CategoryTheory to create E5a
- fine-tune E3 on CategoryTheory to create E5b
- evaluate both on the same held-out split

### Deliverables
- E5a checkpoint
- E5b checkpoint
- adaptation results table

## Day 13: Report drafting

### Recommended report structure
1. research question
2. why ProofWala alone does not identify mechanism
3. reduced experiment matrix
4. matched-budget controls, including prompt-format control
5. results
6. interpretation
7. limitations
8. optional adaptation results, if run

### Deliverables
- 3 to 5 page memo
- figures inserted
- short conclusion per hypothesis

## Day 14: Packaging and reproducibility

### Tasks
- archive configs
- archive split definitions
- archive commands
- archive checkpoint inventory
- archive final figures and tables

### Deliverables
- reproducibility appendix or folder
- final project summary
- one-slide or one-page summary

## Deliverables Checklist

### Required
- E0 sanity-check output
- E1 checkpoint
- E3 checkpoint
- E4 checkpoint
- frozen dataset manifest
- frozen split manifest
- frozen budget-matching note
- base results table
- training summary table
- search diagnostics table
- 3 to 5 figures
- short internal memo
- reproducibility notes

### Optional
- E5a checkpoint
- E5b checkpoint
- adaptation results table
- adaptation figure

## Recommended Figures

### Required figures
1. training loss curves for E1, E3, E4
2. pass@1 and pass@5 comparison chart
3. compilable-tactic rate comparison
4. search-diagnostics chart such as branching factor or early dead-end rate

### Optional figure
5. adaptation comparison for E5a vs E5b

## Interpretation Template

### Claim 1: Does multilingual training help in the pilot setup?
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

- "In our controlled pilot, real multilingual training outperformed pseudo-multilingual training."
- "The multilingual gain appears partly attributable to improved compilable-tactic generation or search behavior."
- "Multilingual pretraining improved CategoryTheory adaptation in our pilot setting." 

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
