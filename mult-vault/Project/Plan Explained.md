# Plan Explained

This project asks a simple question:

**Why does training on both Lean and Coq help a theorem-proving model more than training on only one of them?**

The file [[PLAN]] gives the technical execution plan. This note explains the current version in plain language.

## Big Idea

A [[Concepts/Model|model]] learns from examples in a [[Concepts/Dataset|dataset]]. Here, the examples are proof states and the next proof step.

The project now uses the released [ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset), which already contains proof-step records for Lean, Coq, and multilingual mixtures. That means we do not need to spend days regenerating data with `itp-interface`.

Because three students each have Nexus access, the plan is to train the three core models in parallel:

1. [[Concepts/Monolingual Training|E1 Lean-only training]]
2. [[Concepts/Multilingual Training|E3 real multilingual training]]
3. [[Concepts/Pseudo-multilingual Training|E4 pseudo-multilingual training]]

Released ProofWala checkpoints are still useful as sanity checks and references, but the main comparison should use our own three trained models.

## What Are We Testing?

The plan tests two main explanations.

### Explanation 1: Real Cross-System Transfer

Maybe Lean and Coq share useful proof patterns. If so, learning from both should teach the model something genuinely new.

### Explanation 2: Extra Variation Helps

Maybe the model improves just because it sees more variety, which acts like [[Concepts/Regularization|regularization]].

That is why the plan includes pseudo-multilingual training. It adds variation without adding a real second proof assistant.

## Required Experiments

### E0: Sanity Check

Use [ProofWala-Multilingual](https://huggingface.co/amitayusht/ProofWala-Multilingual) to make sure the code and evaluation setup work.

### E1: Lean-Only Baseline

Train `Salesforce/codet5-small` on the Lean training split from [ProofWalaDataset](https://huggingface.co/datasets/amitayusht/ProofWalaDataset).

### E3: Real Multilingual

Train `Salesforce/codet5-small` on the multilingual split, or on an explicitly constructed Lean+Coq mixture from ProofWalaDataset.

Using the dataset's `multilingual/train` is simpler. Constructing a custom Lean+Coq mixture gives tighter control if the team has time.

### E4: Pseudo-Multilingual

Train `Salesforce/codet5-small` on the original Lean data plus a synthetic Lean variant.

This is the control that asks whether the multilingual gain is really about Coq transfer or mostly about extra variation.

## Team Parallelization

The work can split cleanly across the three students:

- Student 1 trains E1.
- Student 2 trains E3.
- Student 3 trains E4.

Each student should use one Nexus RTX A5000 job:

```text
partition: class
account: class
qos: medium
gpu: rtxa5000:1
cpus: 8
memory: 64GB
time: 2 days
```

If the queue has enough A5000 GPUs, all three trainings can run at the same time.

## Why All Three Models Must Use CodeT5-Small

The released ProofWala models are based on `Salesforce/codet5-base`, so they remain useful references. For our primary Nexus runs, use `Salesforce/codet5-small` to reduce GPU memory use, checkpoint size, and storage pressure.

For a fair comparison, E1, E3, and E4 should all start from:

```text
Salesforce/codet5-small
```

Do not train only one experiment as CodeT5-base. That would mix up the data effect with a model-size effect.

Also do not initialize E4 from ProofWala-Multilingual, because that model has already learned from real Lean + Coq data.

## Expected Runtime

On one Nexus RTX A5000, using batch size 1, 2048-token context, fp16 or bf16, and gradient checkpointing:

| Run | Expected Time |
|---|---:|
| E1 | 6-14 hours |
| E3 | 8-18 hours |
| E4 | 8-20 hours |

If all three students train in parallel, the training phase should take roughly one day of wall-clock time, with a conservative budget of one to two days including queueing, setup, and restarts.

Before full training, run a 100-step calibration. If 100 steps takes `T` minutes, then 5000 steps should take about `T * 50`.

## Important Fairness Rules

The plan says E1, E3, and E4 should be matched as closely as possible on:

- base model
- tokenizer
- prompt format
- sequence length
- training steps
- batch size policy
- evaluation subset
- proof-search budget

Only the training data should differ.

This is important. Otherwise, multilingual training might look better just because it saw more data, trained longer, or used a different setup.

## Pseudo-Multilingual Data

Pseudo-multilingual training should not replace the original Lean data. It should use:

- the original Lean training data
- plus synthetic Lean augmentation

Good transformations are conservative:

- consistent variable renaming
- harmless formatting changes
- selected local identifier renaming where safe
- theorem-name anonymization only if theorem names are actually visible to the model

Bad transformations are ones that:

- change proof meaning
- break parsing
- change prompt headers or field order
- make examples look unnatural
- add a real second proof assistant

The point is to add surface variation without adding real cross-system structure.

## Storage and GitHub

GitHub is for:

- source code
- configs
- scripts
- small manifests
- notes
- small result summaries

Do not put datasets, Hugging Face caches, checkpoints, virtual environments, `.log/`, or full proof dumps in GitHub.

Nexus class home storage is limited, so the team should:

- use explicit Hugging Face cache paths
- start with reduced dataset shards
- keep only the latest few checkpoints
- request class project storage if needed

## How Success Is Measured

The project uses several [[Concepts/Metric|metrics]].

Most important:

- [[Concepts/pass@k]]
- [[Concepts/Compilable Tactic Rate]]
- behavior during [[Concepts/Proof Search|proof search]]

The plan also checks whether models:

- find more valid next steps
- get stuck less often
- search more effectively

This matters because the gain may come from better [[Concepts/Search Calibration|search calibration]], not only from better one-step prediction.

## What The Project Can Conclude

If E3 beats E1 and E4, that is evidence consistent with real cross-system transfer.

If E3 beats E1 but is about the same as E4, that suggests a lot of the gain may come from regularization and extra variation.

If E3 mainly helps on search metrics, that suggests the gain may come more from better search behavior than from deeper one-step prediction.

## Final Takeaway

This is a focused parallel-training pilot.

It does **not** try to solve multilingual theorem proving completely.

It tries to answer one realistic question:

**When multilingual training helps, is it because the second proof system teaches new structure, or because extra variation makes the model generalize better?**
