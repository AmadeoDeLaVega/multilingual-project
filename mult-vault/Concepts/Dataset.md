# Dataset

A [[Dataset]] is the collection of examples used for [[Training]] or evaluation.

In this project, the dataset contains proof states and proof steps from Lean and Coq.

For the updated pilot, it is useful to think of the dataset as having parts:
- a Lean base dataset
- a Coq augmentation used for real multilingual training
- a synthetic Lean augmentation used for pseudo-multilingual training

The plan freezes these parts early so the main comparisons stay interpretable.

Example:
- one item might be: current goal = prove `n + 0 = n`, next step = use simplification.
