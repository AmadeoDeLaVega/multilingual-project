# Pseudo-multilingual Training

[[Pseudo-multilingual Training]] means using one real language plus a modified version of that same language.

The modified version looks different on the surface, but keeps the same meaning.

Purpose:
- test whether extra variation alone helps
- without using a real second proof assistant

In the updated plan, pseudo-multilingual training should use:
- the original Lean training data
- plus synthetic Lean augmentation

It should not replace the original Lean data with transformed-only data.

Important control rule:
- keep the same prompt grammar and prompt field order as the monolingual and multilingual runs
- do not use prompt-format changes as the main source of variation

Because the current ProofWala-style setup often uses `no_steps: True`, the best synthetic changes are ones that affect the visible proof state or tactic text, not long proof-history context.

Example:
- rename variables
- apply safe identifier aliasing when the serialized example still stays natural
- make harmless formatting changes that preserve meaning and parseability

Matching example:

Original Lean example:

```lean
theorem add_zero (n : Nat) : n + 0 = n := by
  simp
```

Possible pseudo-multilingual Lean variant:

```lean
theorem add_zero_alias (x : Nat) : x + 0 = x := by
  simp
```

The goal is not to create a new proof assistant. The goal is to create extra Lean-side variation while keeping the meaning and tactic behavior effectively the same.
