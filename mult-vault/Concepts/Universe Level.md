# Universe Level

A [[Universe Level]] is an index used to organize types into a hierarchy.

The hierarchy prevents paradoxes such as "the type of all types contains itself."

Example:

```text
Nat : Type 0
Type 0 : Type 1
Type 1 : Type 2
```

The exact syntax differs between Lean and Rocq, but the idea is the same: larger universes can contain smaller ones.
