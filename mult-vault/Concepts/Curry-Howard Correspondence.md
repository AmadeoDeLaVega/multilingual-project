# Curry-Howard Correspondence

The [[Curry-Howard Correspondence]] connects logic and programming.

It says:
- propositions behave like types
- proofs behave like programs
- proving a theorem is like constructing a value of a required type

Example:

```text
A -> B
```

As logic, this means "if A then B." As programming, it is the type of a function that takes evidence for `A` and returns evidence for `B`.
