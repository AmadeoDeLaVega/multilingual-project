# Regularization

[[Regularization]] is anything that helps a model avoid memorizing narrow quirks of the training data.

It usually helps the model generalize better to new examples.

In this project, one hypothesis is that multilingual gains may come partly from regularization: adding more variation may make the model less tied to one repository style or one surface syntax.

Pseudo-multilingual training is the main control for that idea.

Example:
- if a model only sees one style of writing proofs, it may overfit to that style
- if it sees more variation, it may learn broader patterns instead
