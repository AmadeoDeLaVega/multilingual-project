# Kernel

A [[Kernel]] is the small trusted checker inside a proof assistant.

The kernel does not need to find proofs. Its job is to verify that a proposed proof term is valid.

Example:

```text
claim: 2 = 2
proof term: reflexivity
kernel result: accepted
```

Tactics, automation, and machine-learning models can suggest proof steps, but the kernel decides whether the final proof is correct.
