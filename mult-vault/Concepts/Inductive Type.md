# Inductive Type

An [[Inductive Type]] is a type defined by its constructors.

Example:

```text
Nat is built from:
- zero : Nat
- succ : Nat -> Nat
```

This says every natural number is either `zero` or repeatedly applying `succ`.

Inductive types are important because they justify pattern matching, recursion, and induction proofs.
