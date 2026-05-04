# Rocq Semantics

[[Rocq Semantics]] is the meaning of Rocq terms as checked by Rocq's [[Kernel]].

Rocq is the current name of Coq. Most papers and older tools still say Coq. Its core formal language is the [[Calculus of Inductive Constructions]].

The core idea is:
- programs, mathematical objects, propositions, and proofs are all terms
- every term has a type
- a theorem is a type
- a proof is a term inhabiting that type

Example:

```coq
Theorem two_eq_two : 2 = 2.
Proof.
  reflexivity.
Qed.
```

The command `reflexivity` builds a proof term for the proposition `2 = 2`. Rocq accepts the theorem only if the kernel can check that term.

Rocq has several [[Sort|sorts]]:
- `Prop` for logical propositions
- `Set` for small computational data
- `Type@{i}` or `Type(i)` for a hierarchy of larger universes

Rocq uses [[Reduction]] and conversion rules to decide when two types or terms count as the same for type checking.

Example:

```coq
Definition twice (n : nat) := n + n.

Example twice_two : twice 2 = 4.
Proof.
  reflexivity.
Qed.
```

This works because `twice 2` unfolds and computes to `4`.

Rocq is [[Constructive Logic|constructive]] by default: it does not need classical axioms for ordinary proofs. Extra [[Axiom|axioms]] can be imported, but then the theorem depends on them. Rocq makes this visible with commands such as `Print Assumptions`.

For this project, the important point is that a generated Rocq tactic must elaborate to a proof term that the Rocq kernel accepts under the current library and axioms.

Sources:
- `Background/Rocq_CIC_Typing_Rules_Reference.html`
- `Background/Cumulative_Inductive_Types_In_Coq_2018.pdf`
- `Background/Consistency_pCuIC_2017.pdf`
