# Token

A [[Token]] is a small piece of text that a model reads.

Depending on the tokenizer, a token might be:
- a full word
- part of a word
- punctuation
- a symbol like `=` or `forall`

Example:
- `forall n : nat, n + 0 = n` is broken into many tokens before the model sees it.

In the updated plan, token counts matter because E1, E3, and E4 should be matched as closely as possible on total training tokens. Otherwise, a larger dataset could look better just because the model saw more text.
