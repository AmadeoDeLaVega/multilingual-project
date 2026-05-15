# E4 Pseudo-Multilingual Audit

Generated on: 2026-05-13

Transformation: `local_rename_v2`

- Candidate identifiers are extracted only from serialized hypothesis binder positions before ` : ` or ` := `.
- Unicode Lean identifier characters, primes, numeric suffixes, and subscript-like suffixes are tokenized as part of the same identifier.
- Generated inaccessible names containing `✝`, metavariable-looking names, `inst*` names, keywords, and common global names are excluded.
- Replacement is token-based, not substring-based; an identifier is not rewritten when it is the suffix of a qualified name such as `Nat.add`.
- String literals are copied without replacement.
- The same deterministic rename map is applied to hypotheses, goals, and proof-step targets.
- `addition_state_info` records `pseudo_variant`, `source_proof_id`, and `rename_map`.

## Aggregate Checks

- audited pseudo records: `50`
- empty rename maps: `0`
- proof-step target changed: `26`
- start goals changed: `50`
- byte-identical transformed records: `0`

Manual inspection sample: first 50 pseudo records from the materialized sample.

## Example 1

- source proof id: `a01573c5-8411-446d-b4ee-e84e981f36c9`
- pseudo proof id: `a01573c5-8411-446d-b4ee-e84e981f36c9-pseudo-local-rename-v2`
- rename map: `{'C': 'pseudo_0', 'D': 'pseudo_1', 'L': 'pseudo_2', 'R': 'pseudo_3', 'h': 'pseudo_4', 'X': 'pseudo_5', 'Y': 'pseudo_6', 'f': 'pseudo_7', 'g': 'pseudo_8'}`
- original proof step: `rw [← h.homEquiv_naturality_left, ← h.homEquiv_naturality_left, coeq_condition]`
- pseudo proof step: `rw [← pseudo_4.homEquiv_naturality_left, ← pseudo_4.homEquiv_naturality_left, coeq_condition]`

Original:

```text
hyp: C : Type u
goal: f ≫
      (h.homEquiv Y (coeq (?m.10919 h X Y f g) (?m.10920 h X Y f g)))
        (coeqHom (?m.10919 h X Y f g) (?m.10920 h X Y f g)) =
    g ≫
      (h.homEquiv Y (coeq (?m.10919 h X Y f g) (?m.10920 h X Y f g)))
        (coeqHom (?m.10919
```

Pseudo:

```text
hyp: pseudo_0 : Type u
goal: pseudo_7 ≫
      (pseudo_4.homEquiv pseudo_6 (coeq (?m.10919 pseudo_4 pseudo_5 pseudo_6 pseudo_7 pseudo_8) (?m.10920 pseudo_4 pseudo_5 pseudo_6 pseudo_7 pseudo_8)))
        (coeqHom (?m.10919 pseudo_4 pseudo_5 pseudo_6 pseudo_7 pseudo_8) (?
```

## Example 2

- source proof id: `0ab5acc8-2eca-4bf1-af4e-daf65051480b`
- pseudo proof id: `0ab5acc8-2eca-4bf1-af4e-daf65051480b-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 'γ': 'pseudo_2', 'δ': 'pseudo_3', 'm': 'pseudo_4', 'μ': 'pseudo_5', 'ν': 'pseudo_6', 'f': 'pseudo_7', 'hfi': 'pseudo_8'}`
- original proof step: `simpa [HasFiniteIntegral] using hfi`
- pseudo proof step: `simpa [HasFiniteIntegral] using pseudo_8`

Original:

```text
hyp: α : Type u_1
goal: HasFiniteIntegral (-f) μ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: HasFiniteIntegral (-pseudo_7) pseudo_5
```

## Example 3

- source proof id: `84b1c220-80db-4ca2-9a50-2ee8fca2ef0e`
- pseudo proof id: `84b1c220-80db-4ca2-9a50-2ee8fca2ef0e-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 'γ': 'pseudo_2', 'ι': 'pseudo_3', 'm': 'pseudo_4', 'μ': 'pseudo_5', 'ν': 'pseudo_6', 'f': 'pseudo_7', 'g': 'pseudo_8', 's': 'pseudo_9', 't': 'pseudo_10'}`
- original proof step: `simp only [union_eq_iUnion, aestronglyMeasurable_iUnion_iff, Bool.forall_bool, cond, and_comm]`
- pseudo proof step: `simp only [union_eq_iUnion, aestronglyMeasurable_iUnion_iff, Bool.forall_bool, cond, and_comm]`

Original:

```text
hyp: α : Type u_1
goal: AEStronglyMeasurable f (Measure.restrict μ (s ∪ t)) ↔
    AEStronglyMeasurable f (Measure.restrict μ s) ∧ AEStronglyMeasurable f (Measure.restrict μ t)
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: AEStronglyMeasurable pseudo_7 (Measure.restrict pseudo_5 (pseudo_9 ∪ pseudo_10)) ↔
    AEStronglyMeasurable pseudo_7 (Measure.restrict pseudo_5 pseudo_9) ∧ AEStronglyMeasurable pseudo_7 (Measure.restrict pseudo_5 pseudo_10)
```

## Example 4

- source proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c`
- pseudo proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'σ': 'pseudo_1', 'τ': 'pseudo_2'}`
- original proof step: `rw [isConj_iff_cycleType_eq]`
- pseudo proof step: `rw [isConj_iff_cycleType_eq]`

Original:

```text
hyp: α : Type u_1
goal: IsConj σ τ ↔ partition σ = partition τ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: IsConj pseudo_1 pseudo_2 ↔ partition pseudo_1 = partition pseudo_2
```

## Example 5

- source proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c`
- pseudo proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'σ': 'pseudo_1', 'τ': 'pseudo_2', 'h': 'pseudo_3'}`
- original proof step: `refine' ⟨fun h => _, fun h => _⟩`
- pseudo proof step: `refine' ⟨fun pseudo_3 => _, fun pseudo_3 => _⟩`

Original:

```text
hyp: α : Type u_1
goal: cycleType σ = cycleType τ ↔ partition σ = partition τ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: cycleType pseudo_1 = cycleType pseudo_2 ↔ partition pseudo_1 = partition pseudo_2
```

## Example 6

- source proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c`
- pseudo proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'σ': 'pseudo_1', 'τ': 'pseudo_2', 'h': 'pseudo_3'}`
- original proof step: `rw [Nat.Partition.ext_iff, parts_partition, parts_partition, ← sum_cycleType, ← sum_cycleType,
  h]`
- pseudo proof step: `rw [Nat.Partition.ext_iff, parts_partition, parts_partition, ← sum_cycleType, ← sum_cycleType,
  pseudo_3]`

Original:

```text
hyp: case refine'_1
goal: partition σ = partition τ
```

Pseudo:

```text
hyp: case refine'_1
goal: partition pseudo_1 = partition pseudo_2
```

## Example 7

- source proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c`
- pseudo proof id: `83d3f3d8-489d-4891-95bb-ced0139c902c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'σ': 'pseudo_1', 'τ': 'pseudo_2', 'h': 'pseudo_3'}`
- original proof step: `rw [← filter_parts_partition_eq_cycleType, ← filter_parts_partition_eq_cycleType, h]`
- pseudo proof step: `rw [← filter_parts_partition_eq_cycleType, ← filter_parts_partition_eq_cycleType, pseudo_3]`

Original:

```text
hyp: case refine'_2
goal: cycleType σ = cycleType τ
```

Pseudo:

```text
hyp: case refine'_2
goal: cycleType pseudo_1 = cycleType pseudo_2
```

## Example 8

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'h': 'pseudo_7', 'd₁': 'pseudo_8', 't₁': 'pseudo_9', 'ih': 'pseudo_10'}`
- original proof step: `induction' l₁ with d₁ t₁ ih`
- pseudo proof step: `induction' pseudo_4 with pseudo_8 pseudo_9 pseudo_10`

Original:

```text
hyp: ι : Type u_1
goal: indexOf a (l₁ ++ l₂) = indexOf a l₁
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: indexOf pseudo_6 (pseudo_4 ++ pseudo_5) = indexOf pseudo_6 pseudo_4
```

## Example 9

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'd₁': 'pseudo_7', 't₁': 'pseudo_8', 'ih': 'pseudo_9', 'h': 'pseudo_10'}`
- original proof step: `rw [List.cons_append]`
- pseudo proof step: `rw [List.cons_append]`

Original:

```text
hyp: case cons
goal: indexOf a (d₁ :: t₁ ++ l₂) = indexOf a (d₁ :: t₁)
```

Pseudo:

```text
hyp: case cons
goal: indexOf pseudo_6 (pseudo_7 :: pseudo_8 ++ pseudo_5) = indexOf pseudo_6 (pseudo_7 :: pseudo_8)
```

## Example 10

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'd₁': 'pseudo_7', 't₁': 'pseudo_8', 'ih': 'pseudo_9', 'h': 'pseudo_10', 'hh': 'pseudo_11'}`
- original proof step: `by_cases hh : d₁ = a`
- pseudo proof step: `by_cases pseudo_11 : pseudo_7 = pseudo_6`

Original:

```text
hyp: case cons
goal: indexOf a (d₁ :: (t₁ ++ l₂)) = indexOf a (d₁ :: t₁)
```

Pseudo:

```text
hyp: case cons
goal: indexOf pseudo_6 (pseudo_7 :: (pseudo_8 ++ pseudo_5)) = indexOf pseudo_6 (pseudo_7 :: pseudo_8)
```

## Example 11

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'd₁': 'pseudo_7', 't₁': 'pseudo_8', 'ih': 'pseudo_9', 'h': 'pseudo_10', 'hh': 'pseudo_11'}`
- original proof step: `rw [indexOf_cons_ne _ hh, indexOf_cons_ne _ hh, ih (mem_of_ne_of_mem (Ne.symm hh) h)]`
- pseudo proof step: `rw [indexOf_cons_ne _ pseudo_11, indexOf_cons_ne _ pseudo_11, pseudo_9 (mem_of_ne_of_mem (Ne.symm pseudo_11) pseudo_10)]`

Original:

```text
hyp: case neg
goal: indexOf a (d₁ :: (t₁ ++ l₂)) = indexOf a (d₁ :: t₁)
```

Pseudo:

```text
hyp: case neg
goal: indexOf pseudo_6 (pseudo_7 :: (pseudo_8 ++ pseudo_5)) = indexOf pseudo_6 (pseudo_7 :: pseudo_8)
```

## Example 12

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'h': 'pseudo_7'}`
- original proof step: `exfalso`
- pseudo proof step: `exfalso`

Original:

```text
hyp: case nil
goal: indexOf a ([] ++ l₂) = indexOf a []
```

Pseudo:

```text
hyp: case nil
goal: indexOf pseudo_6 ([] ++ pseudo_5) = indexOf pseudo_6 []
```

## Example 13

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'h': 'pseudo_7'}`
- original proof step: `exact not_mem_nil a h`
- pseudo proof step: `exact not_mem_nil pseudo_6 pseudo_7`

Original:

```text
hyp: case nil
goal: False
```

Pseudo:

```text
hyp: case nil
goal: False
```

## Example 14

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'd₁': 'pseudo_7', 't₁': 'pseudo_8', 'ih': 'pseudo_9', 'h': 'pseudo_10', 'hh': 'pseudo_11'}`
- original proof step: `iterate 2 rw [indexOf_cons_eq _ hh]`
- pseudo proof step: `iterate 2 rw [indexOf_cons_eq _ pseudo_11]`

Original:

```text
hyp: case pos
goal: indexOf a (d₁ :: (t₁ ++ l₂)) = indexOf a (d₁ :: t₁)
```

Pseudo:

```text
hyp: case pos
goal: indexOf pseudo_6 (pseudo_7 :: (pseudo_8 ++ pseudo_5)) = indexOf pseudo_6 (pseudo_7 :: pseudo_8)
```

## Example 15

- source proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72`
- pseudo proof id: `8d01e465-1863-42b5-82e3-4e04c2ba0e72-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'l₁': 'pseudo_4', 'l₂': 'pseudo_5', 'a': 'pseudo_6', 'd₁': 'pseudo_7', 't₁': 'pseudo_8', 'ih': 'pseudo_9', 'h': 'pseudo_10', 'hh': 'pseudo_11'}`
- original proof step: `rw [indexOf_cons_eq _ hh]`
- pseudo proof step: `rw [indexOf_cons_eq _ pseudo_11]`

Original:

```text
hyp: case pos
goal: 0 = indexOf a (d₁ :: t₁)
```

Pseudo:

```text
hyp: case pos
goal: 0 = indexOf pseudo_6 (pseudo_7 :: pseudo_8)
```

## Example 16

- source proof id: `565bfe93-5234-4ed7-9fa7-893779a9c1f1`
- pseudo proof id: `565bfe93-5234-4ed7-9fa7-893779a9c1f1-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 's': 'pseudo_2'}`
- original proof step: `ext`
- pseudo proof step: `ext`

Original:

```text
hyp: α : Type u_1
goal: eraseNone (insertNone s) = s
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: eraseNone (insertNone pseudo_2) = pseudo_2
```

## Example 17

- source proof id: `565bfe93-5234-4ed7-9fa7-893779a9c1f1`
- pseudo proof id: `565bfe93-5234-4ed7-9fa7-893779a9c1f1-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 's': 'pseudo_2'}`
- original proof step: `simp`
- pseudo proof step: `simp`

Original:

```text
hyp: case a
goal: a✝ ∈ eraseNone (insertNone s) ↔ a✝ ∈ s
```

Pseudo:

```text
hyp: case a
goal: a✝ ∈ eraseNone (insertNone pseudo_2) ↔ a✝ ∈ pseudo_2
```

## Example 18

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4', 'y1': 'pseudo_5', 'y2': 'pseudo_6'}`
- original proof step: `induction y1 using Quotient.inductionOn`
- pseudo proof step: `induction pseudo_5 using Quotient.inductionOn`

Original:

```text
hyp: ι : Type u_1
goal: val (y1 + y2) = val y1 + val y2
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: val (pseudo_5 + pseudo_6) = val pseudo_5 + val pseudo_6
```

## Example 19

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4', 'y2': 'pseudo_5'}`
- original proof step: `induction y2 using Quotient.inductionOn`
- pseudo proof step: `induction pseudo_5 using Quotient.inductionOn`

Original:

```text
hyp: case h
goal: val (⟦a✝⟧ + y2) = val ⟦a✝⟧ + val y2
```

Pseudo:

```text
hyp: case h
goal: val (⟦a✝⟧ + pseudo_5) = val ⟦a✝⟧ + val pseudo_5
```

## Example 20

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4'}`
- original proof step: `change Localization.mk _ _ = Localization.mk _ _ + Localization.mk _ _`
- pseudo proof step: `change Localization.mk _ _ = Localization.mk _ _ + Localization.mk _ _`

Original:

```text
hyp: case h.h
goal: val (⟦a✝¹⟧ + ⟦a✝⟧) = val ⟦a✝¹⟧ + val ⟦a✝⟧
```

Pseudo:

```text
hyp: case h.h
goal: val (⟦a✝¹⟧ + ⟦a✝⟧) = val ⟦a✝¹⟧ + val ⟦a✝⟧
```

## Example 21

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4'}`
- original proof step: `dsimp only`
- pseudo proof step: `dsimp only`

Original:

```text
hyp: case h.h
goal: Localization.mk ↑((fun x_1 x_2 => x_1 + x_2) a✝¹ a✝).num
      { val := ↑((fun x_1 x_2 => x_1 + x_2) a✝¹ a✝).den, property := ⋯ } =
    Localization.mk ↑a✝¹.num { val := ↑a✝¹.den, property := ⋯ } +
      Localization.mk ↑a✝.num { val := ↑a✝
```

Pseudo:

```text
hyp: case h.h
goal: Localization.mk ↑((fun x_1 x_2 => x_1 + x_2) a✝¹ a✝).num
      { val := ↑((fun x_1 x_2 => x_1 + x_2) a✝¹ a✝).den, property := ⋯ } =
    Localization.mk ↑a✝¹.num { val := ↑a✝¹.den, property := ⋯ } +
      Localization.mk ↑a✝.num { val := ↑a✝
```

## Example 22

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4'}`
- original proof step: `rw [Localization.add_mk]`
- pseudo proof step: `rw [Localization.add_mk]`

Original:

```text
hyp: case h.h
goal: Localization.mk ↑(a✝¹ + a✝).num { val := ↑(a✝¹ + a✝).den, property := ⋯ } =
    Localization.mk ↑a✝¹.num { val := ↑a✝¹.den, property := ⋯ } +
      Localization.mk ↑a✝.num { val := ↑a✝.den, property := ⋯ }
```

Pseudo:

```text
hyp: case h.h
goal: Localization.mk ↑(a✝¹ + a✝).num { val := ↑(a✝¹ + a✝).den, property := ⋯ } =
    Localization.mk ↑a✝¹.num { val := ↑a✝¹.den, property := ⋯ } +
      Localization.mk ↑a✝.num { val := ↑a✝.den, property := ⋯ }
```

## Example 23

- source proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45`
- pseudo proof id: `8768c8bb-608d-4ffa-b298-d9e8e8c84d45-pseudo-local-rename-v2`
- rename map: `{'ι': 'pseudo_0', 'R': 'pseudo_1', 'A': 'pseudo_2', '𝒜': 'pseudo_3', 'x': 'pseudo_4'}`
- original proof step: `rfl`
- pseudo proof step: `rfl`

Original:

```text
hyp: case h.h
goal: Localization.mk ↑(a✝¹ + a✝).num { val := ↑(a✝¹ + a✝).den, property := ⋯ } =
    Localization.mk (↑{ val := ↑a✝¹.den, property := ⋯ } * ↑a✝.num + ↑{ val := ↑a✝.den, property := ⋯ } * ↑a✝¹.num)
      ({ val := ↑a✝¹.den, property := ⋯ } * { va
```

Pseudo:

```text
hyp: case h.h
goal: Localization.mk ↑(a✝¹ + a✝).num { val := ↑(a✝¹ + a✝).den, property := ⋯ } =
    Localization.mk (↑{ val := ↑a✝¹.den, property := ⋯ } * ↑a✝.num + ↑{ val := ↑a✝.den, property := ⋯ } * ↑a✝¹.num)
      ({ val := ↑a✝¹.den, property := ⋯ } * { va
```

## Example 24

- source proof id: `2c6723b1-a784-4aae-8329-45ca23698800`
- pseudo proof id: `2c6723b1-a784-4aae-8329-45ca23698800-pseudo-local-rename-v2`
- rename map: `{'n': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'v': 'pseudo_4', 'i': 'pseudo_5', 'j': 'pseudo_6', 'a': 'pseudo_7'}`
- original proof step: `split_ifs <;> (try simp [*])`
- pseudo proof step: `split_ifs <;> (try simp [*])`

Original:

```text
hyp: n : ℕ
goal: get (set v i a) j = if i = j then a else get v j
```

Pseudo:

```text
hyp: pseudo_0 : ℕ
goal: get (set pseudo_4 pseudo_5 pseudo_7) pseudo_6 = if pseudo_5 = pseudo_6 then pseudo_7 else get pseudo_4 pseudo_6
```

## Example 25

- source proof id: `2c6723b1-a784-4aae-8329-45ca23698800`
- pseudo proof id: `2c6723b1-a784-4aae-8329-45ca23698800-pseudo-local-rename-v2`
- rename map: `{'n': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'v': 'pseudo_4', 'i': 'pseudo_5', 'j': 'pseudo_6', 'a': 'pseudo_7'}`
- original proof step: `rwa [get_set_of_ne]`
- pseudo proof step: `rwa [get_set_of_ne]`

Original:

```text
hyp: case neg
goal: get (set v i a) j = get v j
```

Pseudo:

```text
hyp: case neg
goal: get (set pseudo_4 pseudo_5 pseudo_7) pseudo_6 = get pseudo_4 pseudo_6
```

## Example 26

- source proof id: `2c6723b1-a784-4aae-8329-45ca23698800`
- pseudo proof id: `2c6723b1-a784-4aae-8329-45ca23698800-pseudo-local-rename-v2`
- rename map: `{'n': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'v': 'pseudo_4', 'i': 'pseudo_5', 'j': 'pseudo_6', 'a': 'pseudo_7'}`
- original proof step: `try simp [*]`
- pseudo proof step: `try simp [*]`

Original:

```text
hyp: case pos
goal: get (set v i a) j = a
```

Pseudo:

```text
hyp: case pos
goal: get (set pseudo_4 pseudo_5 pseudo_7) pseudo_6 = pseudo_7
```

## Example 27

- source proof id: `2c6723b1-a784-4aae-8329-45ca23698800`
- pseudo proof id: `2c6723b1-a784-4aae-8329-45ca23698800-pseudo-local-rename-v2`
- rename map: `{'n': 'pseudo_0', 'α': 'pseudo_1', 'β': 'pseudo_2', 'γ': 'pseudo_3', 'v': 'pseudo_4', 'i': 'pseudo_5', 'j': 'pseudo_6', 'a': 'pseudo_7'}`
- original proof step: `simp [*]`
- pseudo proof step: `simp [*]`

Original:

```text
hyp: case pos
goal: get (set v i a) j = a
```

Pseudo:

```text
hyp: case pos
goal: get (set pseudo_4 pseudo_5 pseudo_7) pseudo_6 = pseudo_7
```

## Example 28

- source proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4`
- pseudo proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2', 'l': 'pseudo_3', 'hl': 'pseudo_4'}`
- original proof step: `rcases l.surjective_or_eq_zero with (hl | rfl)`
- pseudo proof step: `rcases pseudo_3.surjective_or_eq_zero with (pseudo_4 | rfl)`

Original:

```text
hyp: R : Type u
goal: IsClosed ↑(ker l) ∨ Dense ↑(ker l)
```

Pseudo:

```text
hyp: pseudo_0 : Type u
goal: IsClosed ↑(ker pseudo_3) ∨ Dense ↑(ker pseudo_3)
```

## Example 29

- source proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4`
- pseudo proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2', 'l': 'pseudo_3', 'hl': 'pseudo_4'}`
- original proof step: `exact l.ker.isClosed_or_dense_of_isCoatom (LinearMap.isCoatom_ker_of_surjective hl)`
- pseudo proof step: `exact pseudo_3.ker.isClosed_or_dense_of_isCoatom (LinearMap.isCoatom_ker_of_surjective pseudo_4)`

Original:

```text
hyp: case inl
goal: IsClosed ↑(ker l) ∨ Dense ↑(ker l)
```

Pseudo:

```text
hyp: case inl
goal: IsClosed ↑(ker pseudo_3) ∨ Dense ↑(ker pseudo_3)
```

## Example 30

- source proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4`
- pseudo proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2'}`
- original proof step: `rw [LinearMap.ker_zero]`
- pseudo proof step: `rw [LinearMap.ker_zero]`

Original:

```text
hyp: case inr
goal: IsClosed ↑(ker 0) ∨ Dense ↑(ker 0)
```

Pseudo:

```text
hyp: case inr
goal: IsClosed ↑(ker 0) ∨ Dense ↑(ker 0)
```

## Example 31

- source proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4`
- pseudo proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2'}`
- original proof step: `left`
- pseudo proof step: `left`

Original:

```text
hyp: case inr
goal: IsClosed ↑⊤ ∨ Dense ↑⊤
```

Pseudo:

```text
hyp: case inr
goal: IsClosed ↑⊤ ∨ Dense ↑⊤
```

## Example 32

- source proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4`
- pseudo proof id: `2c98e22a-7935-4730-b879-5f1f4681fbb4-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2'}`
- original proof step: `exact isClosed_univ`
- pseudo proof step: `exact isClosed_univ`

Original:

```text
hyp: case inr.h
goal: IsClosed ↑⊤
```

Pseudo:

```text
hyp: case inr.h
goal: IsClosed ↑⊤
```

## Example 33

- source proof id: `c6bef9a1-1feb-48ff-9f22-2132268d9124`
- pseudo proof id: `c6bef9a1-1feb-48ff-9f22-2132268d9124-pseudo-local-rename-v2`
- rename map: `{'C': 'pseudo_0', 'B': 'pseudo_1', "X'": 'pseudo_2', 'Y': 'pseudo_3', "Y'": 'pseudo_4', 'Z': 'pseudo_5', 'A': 'pseudo_6', 'X': 'pseudo_7'}`
- original proof step: `rw [curry_eq, (exp A).map_id (A ⨯ _)]`
- pseudo proof step: `rw [curry_eq, (exp pseudo_6).map_id (pseudo_6 ⨯ _)]`

Original:

```text
hyp: C : Type u
goal: curry (𝟙 (A ⨯ (𝟭 C).obj X)) = (exp.coev A).app X
```

Pseudo:

```text
hyp: pseudo_0 : Type u
goal: curry (𝟙 (pseudo_6 ⨯ (𝟭 pseudo_0).obj pseudo_7)) = (exp.coev pseudo_6).app pseudo_7
```

## Example 34

- source proof id: `c6bef9a1-1feb-48ff-9f22-2132268d9124`
- pseudo proof id: `c6bef9a1-1feb-48ff-9f22-2132268d9124-pseudo-local-rename-v2`
- rename map: `{'C': 'pseudo_0', 'B': 'pseudo_1', "X'": 'pseudo_2', 'Y': 'pseudo_3', "Y'": 'pseudo_4', 'Z': 'pseudo_5', 'A': 'pseudo_6', 'X': 'pseudo_7'}`
- original proof step: `apply comp_id`
- pseudo proof step: `apply comp_id`

Original:

```text
hyp: C : Type u
goal: (exp.coev A).app ((𝟭 C).obj X) ≫ 𝟙 (A ⟹ A ⨯ (𝟭 C).obj X) = (exp.coev A).app X
```

Pseudo:

```text
hyp: pseudo_0 : Type u
goal: (exp.coev pseudo_6).app ((𝟭 pseudo_0).obj pseudo_7) ≫ 𝟙 (pseudo_6 ⟹ pseudo_6 ⨯ (𝟭 pseudo_0).obj pseudo_7) = (exp.coev pseudo_6).app pseudo_7
```

## Example 35

- source proof id: `20e714b3-ec9c-4074-aba3-a583c8e3e5a5`
- pseudo proof id: `20e714b3-ec9c-4074-aba3-a583c8e3e5a5-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 'γ': 'pseudo_2', 's': 'pseudo_3', 't': 'pseudo_4', 'a': 'pseudo_5', 'b': 'pseudo_6', 'x': 'pseudo_7'}`
- original proof step: `simp [mem_symmDiff, Set.mem_symmDiff]`
- pseudo proof step: `simp [mem_symmDiff, Set.mem_symmDiff]`

Original:

```text
hyp: α : Type u_1
goal: x ∈ ↑(s ∆ t) ↔ x ∈ ↑s ∆ ↑t
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: pseudo_7 ∈ ↑(pseudo_3 ∆ pseudo_4) ↔ pseudo_7 ∈ ↑pseudo_3 ∆ ↑pseudo_4
```

## Example 36

- source proof id: `5525ebe9-9ec4-4751-95bf-5ef53238d238`
- pseudo proof id: `5525ebe9-9ec4-4751-95bf-5ef53238d238-pseudo-local-rename-v2`
- rename map: `{'n': 'pseudo_0'}`
- original proof step: `simp`
- pseudo proof step: `simp`

Original:

```text
hyp: n : ℕ
goal: 1 < n + 2
```

Pseudo:

```text
hyp: pseudo_0 : ℕ
goal: 1 < pseudo_0 + 2
```

## Example 37

- source proof id: `014daeb2-b00c-45e6-82d2-cd9d7e20054b`
- pseudo proof id: `014daeb2-b00c-45e6-82d2-cd9d7e20054b-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'β': 'pseudo_1', 'G': 'pseudo_2', 'a': 'pseudo_3', 'b': 'pseudo_4', 'c': 'pseudo_5', 'd': 'pseudo_6', 'h': 'pseudo_7'}`
- original proof step: `rw [eq_inv_of_mul_eq_one_right h, one_div]`
- pseudo proof step: `rw [eq_inv_of_mul_eq_one_right pseudo_7, one_div]`

Original:

```text
hyp: α : Type u_1
goal: b = 1 / a
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: pseudo_4 = 1 / pseudo_3
```

## Example 38

- source proof id: `1eb43cf2-c39e-4c89-9631-158cfc9a3d7a`
- pseudo proof id: `1eb43cf2-c39e-4c89-9631-158cfc9a3d7a-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'R₁': 'pseudo_1', 'R₂': 'pseudo_2', 'R₃': 'pseudo_3', 'R₄': 'pseudo_4', 'S': 'pseudo_5', 'K': 'pseudo_6', 'K₂': 'pseudo_7', 'M': 'pseudo_8', "M'": 'pseudo_9', 'M₁': 'pseudo_10', 'M₂': 'pseudo_11', 'M₃': 'pseudo_12', 'M₄': 'pseudo_13', 'N': 'pseudo_14', 'N₂': 'pseudo_15', 'ι': 'pseudo_16', 'V': 'pseudo_17', 'V₂': 'pseudo_18', 'τ₁₂': 'pseudo_19', 'τ₂₃': 'pseudo_20', 'τ₁₃': 'pseudo_21', 'f': 'pseudo_22', 'g': 'pseudo_23', 'hf': 'pseudo_24'}`
- original proof step: `rw [range_comp, hf, Submodule.map_top]`
- pseudo proof step: `rw [range_comp, pseudo_24, Submodule.map_top]`

Original:

```text
hyp: R : Type u_1
goal: range (comp g f) = range g
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: range (comp pseudo_23 pseudo_22) = range pseudo_23
```

## Example 39

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `have M : MeasurableSet (Set.Ioc (-A) A) := measurableSet_Ioc`
- pseudo proof step: `have pseudo_9 : MeasurableSet (Set.Ioc (-pseudo_5) pseudo_5) := measurableSet_Ioc`

Original:

```text
hyp: α : Type u_1
goal: ∫ (x : α), truncation f A x ^ n ∂μ = ∫ (y : ℝ) in -A..A, y ^ n ∂Measure.map f μ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: ∫ (x : pseudo_0), truncation pseudo_3 pseudo_5 x ^ pseudo_7 ∂pseudo_2 = ∫ (y : ℝ) in -pseudo_5..A, y ^ pseudo_7 ∂Measure.map pseudo_3 pseudo_2
```

## Example 40

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `change ∫ x, (fun z => indicator (Set.Ioc (-A) A) id z ^ n) (f x) ∂μ = _`
- pseudo proof step: `change ∫ x, (fun z => indicator (Set.Ioc (-pseudo_5) pseudo_5) id z ^ pseudo_7) (pseudo_3 x) ∂pseudo_2 = _`

Original:

```text
hyp: α : Type u_1
goal: ∫ (x : α), truncation f A x ^ n ∂μ = ∫ (y : ℝ) in -A..A, y ^ n ∂Measure.map f μ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: ∫ (x : pseudo_0), truncation pseudo_3 pseudo_5 x ^ pseudo_7 ∂pseudo_2 = ∫ (y : ℝ) in -pseudo_5..A, y ^ pseudo_7 ∂Measure.map pseudo_3 pseudo_2
```

## Example 41

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `rw [← integral_map (f := fun z => _ ^ n) hf.aemeasurable, intervalIntegral.integral_of_le,
  ← integral_indicator M]`
- pseudo proof step: `rw [← integral_map (pseudo_3 := fun z => _ ^ pseudo_7) pseudo_4.aemeasurable, intervalIntegral.integral_of_le,
  ← integral_indicator pseudo_9]`

Original:

```text
hyp: α : Type u_1
goal: ∫ (x : α), (fun z => indicator (Set.Ioc (-A) A) id z ^ n) (f x) ∂μ = ∫ (y : ℝ) in -A..A, y ^ n ∂Measure.map f μ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: ∫ (x : pseudo_0), (fun z => indicator (Set.Ioc (-pseudo_5) pseudo_5) id z ^ pseudo_7) (pseudo_3 x) ∂pseudo_2 = ∫ (y : ℝ) in -pseudo_5..A, y ^ pseudo_7 ∂Measure.map pseudo_3 pseudo_2
```

## Example 42

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `simp only [indicator, zero_pow hn, id.def, ite_pow]`
- pseudo proof step: `simp only [indicator, zero_pow pseudo_8, id.def, ite_pow]`

Original:

```text
hyp: α : Type u_1
goal: ∫ (y : ℝ), indicator (Set.Ioc (-A) A) id y ^ n ∂Measure.map f μ =
    ∫ (x : ℝ), indicator (Set.Ioc (-A) A) (fun x => x ^ n) x ∂Measure.map f μ
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: ∫ (y : ℝ), indicator (Set.Ioc (-pseudo_5) pseudo_5) id y ^ pseudo_7 ∂Measure.map pseudo_3 pseudo_2 =
    ∫ (x : ℝ), indicator (Set.Ioc (-pseudo_5) pseudo_5) (fun x => x ^ pseudo_7) x ∂Measure.map pseudo_3 pseudo_2
```

## Example 43

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `linarith`
- pseudo proof step: `linarith`

Original:

```text
hyp: α : Type u_1
goal: -A ≤ A
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: -pseudo_5 ≤ pseudo_5
```

## Example 44

- source proof id: `da4140c9-aa60-4636-9d5c-70870913114c`
- pseudo proof id: `da4140c9-aa60-4636-9d5c-70870913114c-pseudo-local-rename-v2`
- rename map: `{'α': 'pseudo_0', 'm': 'pseudo_1', 'μ': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'n': 'pseudo_7', 'hn': 'pseudo_8', 'M': 'pseudo_9'}`
- original proof step: `exact ((measurable_id.indicator M).pow_const n).aestronglyMeasurable`
- pseudo proof step: `exact ((measurable_id.indicator pseudo_9).pow_const pseudo_7).aestronglyMeasurable`

Original:

```text
hyp: α : Type u_1
goal: AEStronglyMeasurable (fun z => indicator (Set.Ioc (-A) A) id z ^ n) (Measure.map f μ)
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: AEStronglyMeasurable (fun z => indicator (Set.Ioc (-pseudo_5) pseudo_5) id z ^ pseudo_7) (Measure.map pseudo_3 pseudo_2)
```

## Example 45

- source proof id: `0efce3ee-a844-480c-9c61-61a979ffd58a`
- pseudo proof id: `0efce3ee-a844-480c-9c61-61a979ffd58a-pseudo-local-rename-v2`
- rename map: `{'l': 'pseudo_0', 'm': 'pseudo_1', 'n': 'pseudo_2', 'o': 'pseudo_3', "m'": 'pseudo_4', "n'": 'pseudo_5', 'S': 'pseudo_6', 'α': 'pseudo_7', 'β': 'pseudo_8', 'γ': 'pseudo_9', 'R': 'pseudo_10', 'A': 'pseudo_11', 'B': 'pseudo_12'}`
- original proof step: `rw [Matrix.mul_apply, Finset.sum_fin_eq_sum_range, Finset.sum_range_succ, Finset.sum_range_succ]`
- pseudo proof step: `rw [Matrix.mul_apply, Finset.sum_fin_eq_sum_range, Finset.sum_range_succ, Finset.sum_range_succ]`

Original:

```text
hyp: case refine_4
goal: (A * B) 1 1 = A 1 0 * B 0 1 + A 1 1 * B 1 1
```

Pseudo:

```text
hyp: case refine_4
goal: (pseudo_11 * pseudo_12) 1 1 = pseudo_11 1 0 * pseudo_12 0 1 + pseudo_11 1 1 * pseudo_12 1 1
```

## Example 46

- source proof id: `0efce3ee-a844-480c-9c61-61a979ffd58a`
- pseudo proof id: `0efce3ee-a844-480c-9c61-61a979ffd58a-pseudo-local-rename-v2`
- rename map: `{'l': 'pseudo_0', 'm': 'pseudo_1', 'n': 'pseudo_2', 'o': 'pseudo_3', "m'": 'pseudo_4', "n'": 'pseudo_5', 'S': 'pseudo_6', 'α': 'pseudo_7', 'β': 'pseudo_8', 'γ': 'pseudo_9', 'R': 'pseudo_10', 'A': 'pseudo_11', 'B': 'pseudo_12'}`
- original proof step: `simp`
- pseudo proof step: `simp`

Original:

```text
hyp: case refine_4
goal: (((∑ x in Finset.range 0, if h : x < 2 then A 1 { val := x, isLt := h } * B { val := x, isLt := h } 1 else 0) +
        if h : 0 < 2 then A 1 { val := 0, isLt := h } * B { val := 0, isLt := h } 1 else 0) +
      if h : 1 < 2 then A 1 { val 
```

Pseudo:

```text
hyp: case refine_4
goal: (((∑ x in Finset.range 0, if h : x < 2 then pseudo_11 1 { val := x, isLt := h } * pseudo_12 { val := x, isLt := h } 1 else 0) +
        if h : 0 < 2 then pseudo_11 1 { val := 0, isLt := h } * pseudo_12 { val := 0, isLt := h } 1 else 0) +
  
```

## Example 47

- source proof id: `7f7d3b17-a992-4fcc-b3fe-c6af40ac030f`
- pseudo proof id: `7f7d3b17-a992-4fcc-b3fe-c6af40ac030f-pseudo-local-rename-v2`
- rename map: `{'z': 'pseudo_0', 'n': 'pseudo_1', 'hn': 'pseudo_2', 'x': 'pseudo_3', 'y': 'pseudo_4', 'h': 'pseudo_5', 'hy': 'pseudo_6'}`
- original proof step: `apply_mod_cast exists_rat_pow_btwn_rat_aux hn x y <;> assumption`
- pseudo proof step: `apply_mod_cast exists_rat_pow_btwn_rat_aux pseudo_2 pseudo_3 pseudo_4 <;> assumption`

Original:

```text
hyp: z x✝ y✝ : ℝ
goal: ∃ q, 0 < q ∧ x < q ^ n ∧ q ^ n < y
```

Pseudo:

```text
hyp: pseudo_0 x✝ y✝ : ℝ
goal: ∃ q, 0 < q ∧ pseudo_3 < q ^ pseudo_1 ∧ q ^ pseudo_1 < pseudo_4
```

## Example 48

- source proof id: `a45e9301-bd06-474d-970c-f10e74776331`
- pseudo proof id: `a45e9301-bd06-474d-970c-f10e74776331-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2', 'P': 'pseudo_3', 'Q': 'pseudo_4', 'f': 'pseudo_5', 'g': 'pseudo_6', 'this': 'pseudo_7'}`
- original proof step: `have : g = (Submodule.subtype _).comp g.rangeRestrict := rfl`
- pseudo proof step: `have : pseudo_6 = (Submodule.subtype _).comp pseudo_6.rangeRestrict := rfl`

Original:

```text
hyp: R : Type u_1
goal: range (rTensor Q g) = range (rTensor Q (Submodule.subtype (range g)))
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: range (rTensor pseudo_4 pseudo_6) = range (rTensor pseudo_4 (Submodule.subtype (range pseudo_6)))
```

## Example 49

- source proof id: `a45e9301-bd06-474d-970c-f10e74776331`
- pseudo proof id: `a45e9301-bd06-474d-970c-f10e74776331-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2', 'P': 'pseudo_3', 'Q': 'pseudo_4', 'f': 'pseudo_5', 'g': 'pseudo_6', 'this': 'pseudo_7'}`
- original proof step: `nth_rewrite 1 [this]`
- pseudo proof step: `nth_rewrite 1 [pseudo_7]`

Original:

```text
hyp: R : Type u_1
goal: range (rTensor Q g) = range (rTensor Q (Submodule.subtype (range g)))
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: range (rTensor pseudo_4 pseudo_6) = range (rTensor pseudo_4 (Submodule.subtype (range pseudo_6)))
```

## Example 50

- source proof id: `a45e9301-bd06-474d-970c-f10e74776331`
- pseudo proof id: `a45e9301-bd06-474d-970c-f10e74776331-pseudo-local-rename-v2`
- rename map: `{'R': 'pseudo_0', 'M': 'pseudo_1', 'N': 'pseudo_2', 'P': 'pseudo_3', 'Q': 'pseudo_4', 'f': 'pseudo_5', 'g': 'pseudo_6', 'this': 'pseudo_7'}`
- original proof step: `rw [rTensor_comp]`
- pseudo proof step: `rw [rTensor_comp]`

Original:

```text
hyp: R : Type u_1
goal: range (rTensor Q (Submodule.subtype (range g) ∘ₗ rangeRestrict g)) = range (rTensor Q (Submodule.subtype (range g)))
```

Pseudo:

```text
hyp: pseudo_0 : Type u_1
goal: range (rTensor pseudo_4 (Submodule.subtype (range pseudo_6) ∘ₗ rangeRestrict pseudo_6)) = range (rTensor pseudo_4 (Submodule.subtype (range pseudo_6)))
```
