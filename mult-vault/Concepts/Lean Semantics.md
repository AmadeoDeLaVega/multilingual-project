# Lean Semantics

[[Lean Semantics]] is the meaning of Lean terms as checked by Lean's small [[Kernel]].

Lean is based on [[Type Theory]] with [[Dependent Type|dependent types]], [[Inductive Type|inductive types]], [[Universe Level|universe levels]], and an impredicative `Prop`.

The core idea is:
- every expression has a type
- a theorem is a term whose type is a proposition
- a proof is accepted only when the kernel can check that the proof term has the theorem's type

Example:

```lean
theorem two_eq_two : 2 = 2 := rfl
```

Here `2 = 2` is a proposition, and `rfl` is a proof term. The theorem means: the type `2 = 2` is inhabited by a proof.

Lean also gives terms computational behavior through [[Reduction]]. If two expressions reduce to the same value, Lean may treat them as [[Definitional Equality|definitionally equal]].

Example:

```lean
def twice (n : Nat) := n + n

example : twice 2 = 4 := rfl
```

This works because `twice 2` unfolds and computes to `4`.

Lean has `Prop` for propositions and `Type u` for data-carrying types. `Prop` is proof-irrelevant: once a proposition has a proof, Lean usually does not care which proof it was. Lean also has built-in support for [[Quotient Type|quotient types]], and common libraries often use classical [[Axiom|axioms]] such as choice.

For this project, the important point is that Lean proof search is not just text generation. A generated tactic is useful only if Lean elaborates it into proof terms that the kernel accepts.

Sources:
- `Background/The_Type_Theory_of_Lean.pdf`
- `Background/Lean_Theorem_Prover_System_Description_2015.pdf`
- `Background/Lean4_Theorem_Prover_and_Programming_Language_2021.pdf`
