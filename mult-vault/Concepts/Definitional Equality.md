# Definitional Equality

[[Definitional Equality]] means two expressions count as the same because computation shows they have the same value.

Example:

```text
twice 2
```

If `twice n := n + n`, then `twice 2` is definitionally equal to `4`.

This kind of equality is checked automatically by the kernel. It is different from proving a new theorem by reasoning.
