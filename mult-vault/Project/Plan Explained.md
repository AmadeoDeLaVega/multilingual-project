# Plan Explained

This project asks a simple question:

**Why does training on both Lean and Coq help a theorem-proving model more than training on only one of them?**

The file [[PLAN]] gives the technical execution plan. This note explains it in plain language.

## Big idea

A [[Concepts/Model|model]] learns from examples in a [[Concepts/Dataset|dataset]]. Here, the examples are proof states and the next proof step.

The plan compares three training setups:

1. [[Concepts/Monolingual Training|Monolingual training]]: train only on Lean
2. [[Concepts/Multilingual Training|Multilingual training]]: train on Lean and Coq together
3. [[Concepts/Pseudo-multilingual Training|Pseudo-multilingual training]]: train on Lean plus a modified copy of Lean that looks different on the surface but means the same thing

The main goal is to see **why** multilingual training helps.

One important detail from the updated plan is that pseudo-multilingual training should not replace the original Lean data. It should use:

- the original Lean training data
- plus synthetic Lean augmentation

That makes it a better control for real multilingual training, which also keeps the original Lean data and adds something extra on top.

## What are we testing?

The plan tests two main explanations.

### Explanation 1: real cross-system transfer
Maybe Lean and Coq share useful proof patterns. If so, learning from both should teach the model something genuinely new.

### Explanation 2: extra variation helps
Maybe the model improves just because it sees more variety, which acts like [[Concepts/Regularization|regularization]].

That is why the plan includes pseudo-multilingual training. It adds variation without adding a real second proof assistant.

## Required experiments

The plan keeps only the most important experiments.

### E0: sanity check
Use an already released multilingual model to make sure the code and evaluation setup work.

### E1: Lean-only baseline
Train a [[Concepts/Baseline|baseline]] model only on Lean data.

### E3: real multilingual
Train the same kind of model on Lean + Coq.

### E4: pseudo-multilingual
Train the same kind of model on the original Lean data plus a synthetic Lean variant.

These three comparisons are the core of the project:
- E3 vs E1 asks: does multilingual training help?
- E3 vs E4 asks: is the gain more than just added variation?

## Optional experiment if time remains

### E5: CategoryTheory adaptation
Take the trained models and [[Concepts/Fine-tuning|fine-tune]] them on a small [[Concepts/CategoryTheory Dataset|CategoryTheory dataset]].

This checks [[Concepts/Domain Adaptation|domain adaptation]]: does multilingual pretraining give a better starting point for learning a new area?

This part is useful, but not required for the 2-week project to succeed.

## Why the plan is small

Two weeks is short.

So the plan avoids too many experiments and focuses on one clear causal question:

**Is multilingual gain coming from true cross-system transfer or mostly from regularization?**

## How success is measured

The project uses several [[Concepts/Metric|metrics]].

Most important:
- [[Concepts/pass@k]]
- [[Concepts/Compilable Tactic Rate]]
- behavior during [[Concepts/Proof Search|proof search]]

The plan also checks whether multilingual models:
- find more valid next steps
- get stuck less often
- search more effectively

This matters because the gain may come from better [[Concepts/Search Calibration|search calibration]], not only from better one-step prediction.

## One important fairness rule

The plan says E1, E3, and E4 should be matched as closely as possible on:
- model size
- training steps
- amount of training data, especially in [[Concepts/Token|tokens]]
- prompt format
- evaluation budget

This is important. Otherwise, multilingual might look better just because it saw more data.

The updated plan is especially strict about prompt format because ProofWala multilingual training uses one shared prompt structure across Lean and Coq. So pseudo-multilingual training should not add a different prompt template as its main source of variation.

Another implementation detail is that the current ProofWala-style setup often uses `no_steps: True`. In plain language, that means the model mainly sees the current proof state, not a long history of previous proof steps. So the pseudo-multilingual control should focus on changing the surface form of Lean proof states and tactics, not on inventing different proof-history context.

## What Day 2 and Day 3 now emphasize

The updated schedule gives special attention to the control setup before full training begins.

### Day 2
- freeze the Lean base split
- freeze the Coq augmentation for E3
- define the synthetic Lean augmentation for E4
- decide exactly how token matching and step matching will be enforced

### Day 3
- generate a small E4 sample
- inspect it manually
- verify that it still parses and still uses the same prompt grammar
- run short dry runs for E1, E3, and E4 under the matched-budget rule

This matters because a bad E4 control could make the whole comparison hard to interpret.

## What the project can conclude

If E3 beats E1 and E4, that is evidence for real cross-system transfer.

If E3 beats E1 but is about the same as E4, that suggests a lot of the gain may just come from regularization and extra variation.

If E3 mainly helps on search metrics, that suggests the gain may come more from better search behavior than from deeper reasoning.

## Final takeaway

This is a focused pilot study.

It does **not** try to solve multilingual theorem proving completely.
It tries to answer one realistic question in two weeks:

**When multilingual training helps, is it because the second proof system teaches new structure, or because extra variation makes the model generalize better?**
