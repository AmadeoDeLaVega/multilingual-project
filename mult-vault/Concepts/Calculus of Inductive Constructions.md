# Calculus of Inductive Constructions

The [[Calculus of Inductive Constructions]] is the type theory underlying Rocq and closely related to the foundations used by Lean.

It combines:
- functions from lambda calculus
- [[Dependent Type|dependent types]]
- [[Inductive Type|inductive types]]
- [[Sort|sorts]] such as `Prop` and `Type`

Example:

```coq
forall n : nat, n + 0 = n
```

This is both a logical statement and a type. A proof is a term that works for every natural number `n`.
