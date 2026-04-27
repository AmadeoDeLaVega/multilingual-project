# Multilingual Training

[[Multilingual Training]] means training one model on more than one formal proof language.

In this project, that means training on Lean and Coq together.

In ProofWala-style training, this does not mean paired translations of the same theorem. It means one shared model is trained on a mixed corpus of Lean and Coq proof-state to tactic examples.

The updated plan assumes multilingual training keeps the same prompt grammar across languages and adds Coq data on top of the Lean base data.

Example:
- the model may see a Lean proof example, then a Coq proof example, and learn patterns from both.

Simple Lean example:

```lean
theorem add_zero (n : Nat) : n + 0 = n := by
  simp
```

Simple Coq example:

```coq
Theorem add_zero : forall n : nat, n + 0 = n.
Proof.
  intros n.
  simpl.
  reflexivity.
Qed.
```

In multilingual training, one shared model can see both of these kinds of examples in the same training run, even though they come from different proof assistants.
