# Compilable Tactic Rate

[[Compilable Tactic Rate]] is how often the model suggests a tactic that the proof assistant accepts as valid syntax and executable in the current state.

Example:
- if a model suggests 100 tactics and 40 of them run without error, the compilable tactic rate is 40%

This matters because a model can only help search if its suggestions actually run.

In the updated plan, this is a primary metric because a multilingual model may help search by producing more runnable tactics, even if its exact next-step match rate does not improve much.
