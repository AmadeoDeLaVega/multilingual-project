# Reduction

[[Reduction]] is computation inside the logic.

When a proof assistant checks a proof, it may simplify expressions by unfolding definitions, applying functions, or evaluating pattern matches.

Example:

```text
twice 2
```

If `twice n := n + n`, then `twice 2` reduces to `4`.

This matters because proof assistants can accept equality proofs when both sides reduce to the same [[Normal Form|normal form]].
