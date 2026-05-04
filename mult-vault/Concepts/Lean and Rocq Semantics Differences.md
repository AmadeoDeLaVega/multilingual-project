# Lean and Rocq Semantics Differences

Lean and Rocq are close relatives. Both are proof assistants based on [[Type Theory]], both use [[Dependent Type|dependent types]], and both trust a small [[Kernel]] to check proofs.

The main difference is not that one has semantics and the other does not. The difference is the exact type theory implemented by each kernel.

## Sorts

Lean uses:

```lean
#check Prop
#check Type
#check Type 1
```

Rocq uses:

```coq
Check Prop.
Check Set.
Check Type.
```

Lean has `Prop` and a hierarchy of `Type u`. Rocq has `Prop`, `Set`, and a hierarchy of `Type` universes. This matters because Rocq explicitly distinguishes proposition-only content from [[Program Extraction|extractable]] computational data in `Set`.

## Proofs as terms

In both systems, a theorem is a type and a proof is a term.

Lean:

```lean
theorem two_eq_two : 2 = 2 := rfl
```

Rocq:

```coq
Theorem two_eq_two : 2 = 2.
Proof.
  reflexivity.
Qed.
```

These look different, but semantically both say: construct a term of the equality type `2 = 2`.

## Definitional equality

Both systems use [[Reduction]] during type checking.

Lean:

```lean
def twice (n : Nat) := n + n
example : twice 2 = 4 := rfl
```

Rocq:

```coq
Definition twice (n : nat) := n + n.
Example twice_two : twice 2 = 4.
Proof. reflexivity. Qed.
```

In both cases, the proof works because the expression computes before the kernel compares both sides.

## Quotients and proof irrelevance

Lean has built-in support for [[Quotient Type|quotient types]] and treats proofs in `Prop` as [[Proof Irrelevance|proof-irrelevant]].

Rocq is more conservative in the kernel. Quotient-like reasoning is often done with [[Setoid|setoids]] or added libraries, and proof irrelevance is commonly treated as an optional axiom rather than a built-in [[Definitional Equality|definitional]] behavior.

Example intuition:
- Lean can directly form a quotient type such as "integers as pairs of natural numbers modulo an equivalence relation."
- Rocq often represents the same idea by carrying an equivalence relation and proving that functions respect it.

## Axioms and classical reasoning

Lean libraries often use classical principles such as choice, especially in mathematics.

Rocq starts [[Constructive Logic|constructively]] and makes imported classical principles explicit.

This does not mean Rocq cannot do classical mathematics. It means the dependency on [[Axiom|axioms]] is usually more visible.

## Project implication

For multilingual proof-search experiments, Lean and Rocq examples may look syntactically similar, but their kernels accept different proof objects under slightly different foundations. A model can transfer tactic patterns, but final success is still decided by each prover's own semantics.

Sources:
- `Background/The_Type_Theory_of_Lean.pdf`
- `Background/Lean_Theorem_Prover_System_Description_2015.pdf`
- `Background/Rocq_CIC_Typing_Rules_Reference.html`
- `Background/Cumulative_Inductive_Types_In_Coq_2018.pdf`
