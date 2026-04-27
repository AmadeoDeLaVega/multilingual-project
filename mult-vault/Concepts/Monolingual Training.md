# Monolingual Training

[[Monolingual Training]] means training on one proof language only.

In this plan, the main monolingual setup is Lean-only.

In the updated pilot, monolingual training keeps the same model family, tokenizer, and prompt grammar as the other experiments. The main difference is only the training data source.

Example:
- the model sees only Lean proof states and Lean proof steps during training.

Simple Lean example:

```lean
theorem add_zero (n : Nat) : n + 0 = n := by
  simp
```

In a monolingual Lean setup, the training example would come only from Lean-style proof states and Lean tactics such as `simp`.
