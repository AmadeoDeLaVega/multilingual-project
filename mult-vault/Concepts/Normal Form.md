# Normal Form

A [[Normal Form]] is an expression that cannot be reduced any further under a chosen reduction strategy.

Example:

```text
(fun x => x + 1) 2
```

This reduces to `3`, which is in normal form for ordinary arithmetic evaluation.

Kernels use normal forms, or related conversion procedures, to compare terms during type checking.
