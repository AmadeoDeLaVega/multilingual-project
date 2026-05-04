# Program Extraction

[[Program Extraction]] turns verified definitions into executable code in another programming language.

Example:

```text
verified sorting function in Rocq
-> extracted OCaml function
```

Proof-only content is usually erased, while computational content remains.

This is why proof assistants distinguish propositions from data that should run at execution time.
