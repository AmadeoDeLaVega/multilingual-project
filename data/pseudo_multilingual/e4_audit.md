# E4 Pseudo-Multilingual Smoke Audit

Generated on: 2026-05-04

Transformation: `local_rename_v1`

- Proof-step targets are updated with the same local identifier rename map.
- Pseudo records get a new `proof_id` suffix.
- Local identifiers parsed from hypotheses are renamed consistently to `pseudo_0`, `pseudo_1`, ...
- The same local rename map is applied to hypotheses, goals, and proof steps.
- Minor spacing/indentation changes are applied after renaming.
- `addition_state_info` records the source proof id.

Manual inspection sample: first 50 pseudo records.

## Example 1

- source proof id: `586964aa-4184-455b-9d2c-453f8c2296a8`
- pseudo proof id: `586964aa-4184-455b-9d2c-453f8c2296a8-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'b': 'pseudo_1', 'l': 'pseudo_2', 'hl': 'pseudo_3', 'a': 'pseudo_4'}`
- original proof step: `split_ifs`
- pseudo proof step: `split_ifs`

Original:

```text
hyp: case cons
goal: (if R a b then a :: destutter' R b l else destutter' R a l) <+ a :: b :: l
```

Pseudo:

```text
hyp: case
  cons
goal: (if pseudo_0 pseudo_4 pseudo_1 then pseudo_4 :: destutter' pseudo_0 pseudo_1 pseudo_2 else destutter' pseudo_0 pseudo_4 pseudo_2)  <+  pseudo_4 :: pseudo_1 :: pseudo_2
```

## Example 2

- source proof id: `fcfc8bd8-4f97-47c2-b3aa-6d26519b18fd`
- pseudo proof id: `fcfc8bd8-4f97-47c2-b3aa-6d26519b18fd-pseudo-local-rename-v1`
- rename map: `{'p': 'pseudo_0', 'hp': 'pseudo_1', 'n': 'pseudo_2', 'b': 'pseudo_3', 'hb': 'pseudo_4'}`
- original proof step: `rw [multiplicity_factorial hp ((log_mono_right <| le_succ _).trans_lt hb), ←
  multiplicity_eq_card_pow_dvd hp.ne_one (succ_pos _) hb]`
- pseudo proof step: `rw [multiplicity_factorial pseudo_1 ((log_mono_right <| le_succ _).trans_lt pseudo_4), ←
  multiplicity_eq_card_pow_dvd pseudo_1.ne_one (succ_pos _) pseudo_4]`

Original:

```text
hyp: p : ℕ
goal: multiplicity p n ! + multiplicity p (n + 1) =
    ↑(∑ i in Ico 1 b, n / p ^ i) + ↑(filter (fun i => p ^ i ∣ n + 1) (Ico 1 b)).card
```

Pseudo:

```text
hyp: pseudo_0  :  ℕ
goal: multiplicity pseudo_0 pseudo_2 !  +  multiplicity pseudo_0 (pseudo_2 + 1) =
      ↑(∑ i in Ico 1 pseudo_3, pseudo_2 / pseudo_0 ^ i) + ↑(filter (fun i => pseudo_0 ^ i ∣ pseudo_2 + 1) (Ico 1 pseudo_3)).card
```

## Example 3

- source proof id: `58c20fc5-05e3-4bbf-a27c-d7dc83909b65`
- pseudo proof id: `58c20fc5-05e3-4bbf-a27c-d7dc83909b65-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'J': 'pseudo_1', 'D': 'pseudo_2', 'E': 'pseudo_3', 'F': 'pseudo_4', 'G': 'pseudo_5', 'adj': 'pseudo_6', 'Y': 'pseudo_7'}`
- original proof step: `rfl`
- pseudo proof step: `rfl`

Original:

```text
hyp: C : Type u
goal: ((sheafEquivSheafOfTypes J).symm.unit.app Y).val ≫
      ((Adjunction.whiskerRight Cᵒᵖ adj).homEquiv Y.val ((presheafToSheaf J D).obj (Y.val ⋙ G)).val)
        (toSheafify J (Y.val ⋙ G)) =
    (Adjunction.whiskerRight Cᵒᵖ adj).unit.app Y.va
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: ((sheafEquivSheafOfTypes pseudo_1).symm.unit.app pseudo_7).val ≫
        ((Adjunction.whiskerRight pseudo_0ᵒᵖ pseudo_6).homEquiv pseudo_7.val ((presheafToSheaf pseudo_1 pseudo_2).obj (pseudo_7.val ⋙ pseudo_5)).val)
          (toSheafify pse
```

## Example 4

- source proof id: `96091f52-7a4a-4549-90af-4a445fc9c6be`
- pseudo proof id: `96091f52-7a4a-4549-90af-4a445fc9c6be-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'D': 'pseudo_1', 'F': 'pseudo_2', "F'": 'pseudo_3', 'G': 'pseudo_4', 'adj1': 'pseudo_5', 'adj2': 'pseudo_6', 'x': 'pseudo_7'}`
- original proof step: `ext x`
- pseudo proof step: `ext pseudo_7`

Original:

```text
hyp: C : Type u₁
goal: whiskerLeft G (leftAdjointUniq adj1 adj2).hom ≫ adj2.counit = adj1.counit
```

Pseudo:

```text
hyp: pseudo_0  :  Type u₁
goal: whiskerLeft pseudo_4 (leftAdjointUniq pseudo_5 pseudo_6).hom ≫ pseudo_6.counit  =  pseudo_5.counit
```

## Example 5

- source proof id: `91807ab4-e153-4f87-83da-9dc032ebbabb`
- pseudo proof id: `91807ab4-e153-4f87-83da-9dc032ebbabb-pseudo-local-rename-v1`
- rename map: `{'M': 'pseudo_0'}`
- original proof step: `ext`
- pseudo proof step: `ext`

Original:

```text
hyp: α : Type u_1
goal: lookupFinsupp ∅ = 0
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: lookupFinsupp ∅  =  0
```

## Example 6

- source proof id: `be2ea45a-02ef-446d-9d61-571cbd12932a`
- pseudo proof id: `be2ea45a-02ef-446d-9d61-571cbd12932a-pseudo-local-rename-v1`
- rename map: `{'V': 'pseudo_0', 'P': 'pseudo_1', 's': 'pseudo_2', 'ps': 'pseudo_3', 'hnps': 'pseudo_4', 'p': 'pseudo_5', 'hps': 'pseudo_6', 'hp': 'pseudo_7', 'this': 'pseudo_8', 'cc': 'pseudo_9', 'cr': 'pseudo_10', 'hcccru': 'pseudo_11', 'hcc': 'pseudo_12', 'hcr': 'pseudo_13', 'x': 'pseudo_14', 'y': 'pseudo_15', 'hy0': 'pseudo_16', 'hpo': 'pseudo_17'}`
- original proof step: `rw [show
    x * x + (1 - t₃) * (1 - t₃) * (y * y) = x * x + y * y - 2 * y * (t₃ * y) + t₃ * y * (t₃ * y)
    by ring,
  add_left_inj] at hcr₃`
- pseudo proof step: `rw [show
    pseudo_14 * pseudo_14 + (1 - t₃) * (1 - t₃) * (pseudo_15 * pseudo_15) = pseudo_14 * pseudo_14 + pseudo_15 * pseudo_15 - 2 * pseudo_15 * (t₃ * pseudo_15) + t₃ * pseudo_15 * (t₃ * pseudo_15)
    by ring,
  add_left_inj] at pseudo_13₃`

Original:

```text
hyp: case h.right.mk.intro.intro.intro.intro.intro.refl
goal: { center := cc₃, radius := cr₃ } = { center := cc₂, radius := cr₂ }
```

Pseudo:

```text
hyp: case
  h.right.mk.intro.intro.intro.intro.intro.refl
goal: { center := pseudo_9₃, radius := pseudo_10₃ }  =  { center := pseudo_9₂, radius := pseudo_10₂ }
```

## Example 7

- source proof id: `1cc9b0a8-3ec1-4ff9-b40a-7f228dca8149`
- pseudo proof id: `1cc9b0a8-3ec1-4ff9-b40a-7f228dca8149-pseudo-local-rename-v1`
- rename map: `{'abv': 'pseudo_0', 'f': 'pseudo_1', 'g': 'pseudo_2', 'hg': 'pseudo_3', 'G': 'pseudo_4', 'G0': 'pseudo_5', 'hG': 'pseudo_6', 'i': 'pseudo_7', 'H': 'pseudo_8', 'j': 'pseudo_9', 'ij': 'pseudo_10', 'this': 'pseudo_11'}`
- original proof step: `rwa [div_mul_cancel₀ _ (ne_of_gt G0), ← abv_mul] at this`
- pseudo proof step: `rwa [div_mul_cancel₀ _ (ne_of_gt pseudo_5), ← abv_mul] at pseudo_11`

Original:

```text
hyp: α : Type u_1
goal: abv (↑(f * g) j) < ε
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: pseudo_0 (↑(pseudo_1  *  pseudo_2) pseudo_9) < ε
```

## Example 8

- source proof id: `aa2a9444-5302-4afc-b87b-43ba2872ee8b`
- pseudo proof id: `aa2a9444-5302-4afc-b87b-43ba2872ee8b-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 's': 'pseudo_1', 'f': 'pseudo_2', 't': 'pseudo_3', 'ht': 'pseudo_4'}`
- original proof step: `rw [mem_map, mem_ae_iff, Set.indicator_preimage, Set.ite, Set.compl_union, Set.compl_inter]`
- pseudo proof step: `rw [mem_map, mem_ae_iff, Set.indicator_preimage, Set.ite, Set.compl_union, Set.compl_inter]`

Original:

```text
hyp: R : Type u_1
goal: t ∈ Filter.map (indicator s f) (ae μ) ↔ ↑↑μ ((f ⁻¹' t)ᶜ ∪ sᶜ) = 0
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: pseudo_3 ∈ Filter.map (indicator pseudo_1 pseudo_2) (ae μ) ↔ ↑↑μ ((pseudo_2 ⁻¹' pseudo_3)ᶜ ∪ pseudo_1ᶜ)  =  0
```

## Example 9

- source proof id: `71e12376-297b-41e0-9177-9fd23deecb02`
- pseudo proof id: `71e12376-297b-41e0-9177-9fd23deecb02-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'S': 'pseudo_1', 'h': 'pseudo_2', 'A': 'pseudo_3', 'k': 'pseudo_4', 'hk': 'pseudo_5'}`
- original proof step: `simp only [← cancel_epi (S₁.pOpcycles), p_opcyclesMap_assoc, p_descOpcycles]`
- pseudo proof step: `simp only [← cancel_epi (pseudo_1₁.pOpcycles), p_opcyclesMap_assoc, p_descOpcycles]`

Original:

```text
hyp: C : Type u_1
goal: opcyclesMap φ ≫ descOpcycles S k hk = descOpcycles S₁ (φ.τ₂ ≫ k) ⋯
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: opcyclesMap φ ≫ descOpcycles pseudo_1 pseudo_4 pseudo_5  =  descOpcycles pseudo_1₁ (φ.τ₂ ≫ pseudo_4) ⋯
```

## Example 10

- source proof id: `10033bee-22fe-456a-a02d-5344c5dc86b3`
- pseudo proof id: `10033bee-22fe-456a-a02d-5344c5dc86b3-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'k': 'pseudo_1', 'm': 'pseudo_2', 'n': 'pseudo_3', 'n_dvd': 'pseudo_4', 'hn': 'pseudo_5'}`
- original proof step: `exact cast_div n_dvd (cast_ne_zero.2 hn)`
- pseudo proof step: `exact cast_div pseudo_4 (cast_ne_zero.2 pseudo_5)`

Original:

```text
hyp: case inr
goal: ↑(m / n) = ↑m / ↑n
```

Pseudo:

```text
hyp: case
  inr
goal: ↑(pseudo_2 / pseudo_3)  =  ↑pseudo_2 / ↑pseudo_3
```

## Example 11

- source proof id: `b5453566-c6f5-445b-8903-1b7cb8f34aa3`
- pseudo proof id: `b5453566-c6f5-445b-8903-1b7cb8f34aa3-pseudo-local-rename-v1`
- rename map: `{'I': 'pseudo_0', 'C': 'pseudo_1', 'o': 'pseudo_2', 'hC': 'pseudo_3', 'hsC': 'pseudo_4', 'ho': 'pseudo_5', 'l': 'pseudo_6', 'hl': 'pseudo_7', 'hlh': 'pseudo_8', 'hlc': 'pseudo_9'}`
- original proof step: `rw [max_eq_o_cons_tail' ho l hl hlh hlc, Products.evalCons]`
- pseudo proof step: `rw [max_eq_o_cons_tail' pseudo_5 pseudo_6 pseudo_7 pseudo_8 pseudo_9, Products.evalCons]`

Original:

```text
hyp: I : Type u
goal: (Linear_CC' C hsC ho) (eval C l) = eval (C' C ho) (Tail l)
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: (Linear_CC' pseudo_1 pseudo_4 pseudo_5) (eval pseudo_1 pseudo_6)  =  eval (C' pseudo_1 pseudo_5) (Tail pseudo_6)
```

## Example 12

- source proof id: `7a8e2ebe-ac77-4c6e-827f-d56896cca8e2`
- pseudo proof id: `7a8e2ebe-ac77-4c6e-827f-d56896cca8e2-pseudo-local-rename-v1`
- rename map: `{'f': 'pseudo_0', 'g': 'pseudo_1', 'X': 'pseudo_2', 'Y': 'pseudo_3', 'hXY': 'pseudo_4', "h'XY": 'pseudo_5', 'hX': 'pseudo_6', 'hY': 'pseudo_7', "h'X": 'pseudo_8', 'I': 'pseudo_9', 'H': 'pseudo_10', 'J': 'pseudo_11', 'A': 'pseudo_12'}`
- original proof step: `simp only [ENNReal.mul_top I, lt_self_iff_false] at A`
- pseudo proof step: `simp only [ENNReal.mul_top pseudo_9, lt_self_iff_false] at pseudo_12`

Original:

```text
hyp: Ω : Type u_1
goal: False
```

Pseudo:

```text
hyp: Ω  :  Type u_1
goal: False

```

## Example 13

- source proof id: `06b31ad5-17e0-4eb8-ad98-95b7aef65fec`
- pseudo proof id: `06b31ad5-17e0-4eb8-ad98-95b7aef65fec-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'D': 'pseudo_1', 'W': 'pseudo_2', 'X': 'pseudo_3', 'Y': 'pseudo_4', 'Z': 'pseudo_5'}`
- original proof step: `rw [← Iso.eq_inv_comp, pullbackAssoc_inv_fst_fst]`
- pseudo proof step: `rw [← Iso.eq_inv_comp, pullbackAssoc_inv_fst_fst]`

Original:

```text
hyp: C : Type u
goal: (pullbackAssoc f₁ f₂ f₃ f₄).hom ≫ pullback.fst = pullback.fst ≫ pullback.fst
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: (pullbackAssoc f₁ f₂ f₃ f₄).hom ≫ pullback.fst  =  pullback.fst ≫ pullback.fst
```

## Example 14

- source proof id: `03bf24f3-04f1-4d1c-b576-61615cc6d55a`
- pseudo proof id: `03bf24f3-04f1-4d1c-b576-61615cc6d55a-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'S': 'pseudo_1', 'F': 'pseudo_2', 'f': 'pseudo_3', 'hf': 'pseudo_4', 'I': 'pseudo_5', 'h': 'pseudo_6', 'j': 'pseudo_7', 'J': 'pseudo_8', 'hJ': 'pseudo_9', "hJ'": 'pseudo_10', 'this': 'pseudo_11'}`
- original proof step: `exact ⟨hJ' ▸ map_mono hJ.left, hJ' ▸ map_isPrime_of_surjective hf (le_trans h hJ.left)⟩`
- pseudo proof step: `exact ⟨pseudo_10 ▸ map_mono pseudo_9.left, pseudo_10 ▸ map_isPrime_of_surjective pseudo_4 (le_trans pseudo_6 pseudo_9.left)⟩`

Original:

```text
hyp: case h.e'_3.h.e'_3.refine'_2.intro.intro
goal: {J | map f I ≤ J ∧ IsPrime J} j
```

Pseudo:

```text
hyp: case
  pseudo_6.e'_3.pseudo_6.e'_3.refine'_2.intro.intro
goal: {pseudo_8 | map pseudo_3 pseudo_5 ≤ pseudo_8  ∧  IsPrime pseudo_8} pseudo_7
```

## Example 15

- source proof id: `4f582eba-19cf-4568-ba59-f99fbc887425`
- pseudo proof id: `4f582eba-19cf-4568-ba59-f99fbc887425-pseudo-local-rename-v1`
- rename map: `{'m': 'pseudo_0', 'n': 'pseudo_1', 'h': 'pseudo_2', 'h1': 'pseudo_3'}`
- original proof step: `exact coprime_sq_sub_mul_of_even_odd h h1.left h1.right`
- pseudo proof step: `exact coprime_sq_sub_mul_of_even_odd pseudo_2 pseudo_3.left pseudo_3.right`

Original:

```text
hyp: case inl
goal: Int.gcd (m ^ 2 - n ^ 2) (2 * m * n) = 1
```

Pseudo:

```text
hyp: case
  inl
goal: Int.gcd (pseudo_0 ^ 2 - pseudo_1 ^ 2) (2 * pseudo_0 * pseudo_1)  =  1
```

## Example 16

- source proof id: `9ea0fbb8-9e25-48cb-ace9-35503af57e52`
- pseudo proof id: `9ea0fbb8-9e25-48cb-ace9-35503af57e52-pseudo-local-rename-v1`
- rename map: `{'a': 'pseudo_0', 'l': 'pseudo_1'}`
- original proof step: `simp`
- pseudo proof step: `simp`

Original:

```text
hyp: α : Type u_1
goal: toList (cons a l) = a :: toList l
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: toList (cons pseudo_0 pseudo_1)  =  pseudo_0 :: toList pseudo_1
```

## Example 17

- source proof id: `3e9bad21-1e0e-4159-9db3-b102ea48a43b`
- pseudo proof id: `3e9bad21-1e0e-4159-9db3-b102ea48a43b-pseudo-local-rename-v1`
- rename map: `{'x_large': 'pseudo_0', 'f': 'pseudo_1', "hf'": 'pseudo_2', 'x': 'pseudo_3', 'h5': 'pseudo_4', 'h6': 'pseudo_5', 'h7': 'pseudo_6'}`
- original proof step: `have h7 := rpow_pos_of_pos h6 (sqrt (2 * x))`
- pseudo proof step: `have pseudo_6 := rpow_pos_of_pos pseudo_5 (sqrt (2 * pseudo_3))`

Original:

```text
hyp: x✝ : ℝ
goal: f x = log (x * (2 * x) ^ sqrt (2 * x) / 4 ^ (x / 3))
```

Pseudo:

```text
hyp: pseudo_3✝  :  ℝ
goal: pseudo_1 pseudo_3  =  log (pseudo_3 * (2 * pseudo_3) ^ sqrt (2 * pseudo_3) / 4 ^ (pseudo_3 / 3))
```

## Example 18

- source proof id: `f90e3312-2acb-4112-a8b2-a5b4ca54381c`
- pseudo proof id: `f90e3312-2acb-4112-a8b2-a5b4ca54381c-pseudo-local-rename-v1`
- rename map: `{'F': 'pseudo_0', 's': 'pseudo_1', 'a': 'pseudo_2', 'h': 'pseudo_3', 'b': 'pseudo_4'}`
- original proof step: `obtain ⟨b, h, _⟩ := le_sup (α := WithBot α) h _ rfl`
- pseudo proof step: `obtain ⟨pseudo_4, pseudo_3, _⟩ := le_sup (α := WithBot α) pseudo_3 _ rfl`

Original:

```text
hyp: F : Type u_1
goal: ∃ b, Finset.max s = ↑b
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: ∃ pseudo_4, Finset.max pseudo_1  =  ↑pseudo_4
```

## Example 19

- source proof id: `92b7b840-56ac-460b-a54a-1508b4c55ad3`
- pseudo proof id: `92b7b840-56ac-460b-a54a-1508b4c55ad3-pseudo-local-rename-v1`
- rename map: `{'a': 'pseudo_0', "a'": 'pseudo_1', 'b': 'pseudo_2', "b'": 'pseudo_3', 'm': 'pseudo_4', 'f': 'pseudo_5', 'h': 'pseudo_6', "a''": 'pseudo_7'}`
- original proof step: `rcases eq_or_ne a'' a' with (rfl | h₂)`
- pseudo proof step: `rcases eq_or_ne pseudo_7 pseudo_1 with (rfl | pseudo_6₂)`

Original:

```text
hyp: case inl
goal: HEq (cons (a' ::ₘ m) a b (cons m a' b' f) a'' ha₁) (cons (a ::ₘ m) a' b' (cons m a b f) a'' ha₂)
```

Pseudo:

```text
hyp: case
  inl
goal: HEq
  (cons (pseudo_1 ::ₘ pseudo_4) pseudo_0 pseudo_2 (cons pseudo_4 pseudo_1 pseudo_3 pseudo_5) pseudo_7 ha₁) (cons (pseudo_0 ::ₘ pseudo_4) pseudo_1 pseudo_3 (cons pseudo_4 pseudo_0 pseudo_2 pseudo_5) pseudo_7 ha₂)
```

## Example 20

- source proof id: `54ea607a-2810-499f-a4ae-3d0a46b54208`
- pseudo proof id: `54ea607a-2810-499f-a4ae-3d0a46b54208-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'f': 'pseudo_1', 'g': 'pseudo_2', 'a': 'pseudo_3', 'h': 'pseudo_4'}`
- original proof step: `simpa only using h.map (AddMonoidHom.mulLeft a₂) (continuous_const.mul continuous_id)`
- pseudo proof step: `simpa only using pseudo_4.map (AddMonoidHom.mulLeft pseudo_3₂) (continuous_const.mul continuous_id)`

Original:

```text
hyp: ι : Type u_1
goal: HasSum (fun i => a₂ * f i) (a₂ * a₁)
```

Pseudo:

```text
hyp: ι  :  Type u_1
goal: HasSum (fun i => pseudo_3₂  *  pseudo_1 i) (pseudo_3₂ * pseudo_3₁)
```

## Example 21

- source proof id: `e639a232-a07a-49b5-8800-30336dccfb2c`
- pseudo proof id: `e639a232-a07a-49b5-8800-30336dccfb2c-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'X': 'pseudo_1', 'Y': 'pseudo_2', 'f': 'pseudo_3', 'this': 'pseudo_4'}`
- original proof step: `have : Mono α.τ₃ := by dsimp; infer_instance`
- pseudo proof step: `have : Mono α.τ₃ := by dsimp; infer_instance`

Original:

```text
hyp: C : Type u
goal: ShortComplex.Exact (ShortComplex.mk (d f) f ⋯)
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: ShortComplex.Exact
  (ShortComplex.mk (d pseudo_3) pseudo_3 ⋯)
```

## Example 22

- source proof id: `12e9f22a-295f-47e7-ab7c-025d10082107`
- pseudo proof id: `12e9f22a-295f-47e7-ab7c-025d10082107-pseudo-local-rename-v1`
- rename map: `{'f': 'pseudo_0', 'g': 'pseudo_1', 'm': 'pseudo_2'}`
- original proof step: `simp only [Filter.lift, comap_iInf]`
- pseudo proof step: `simp only [Filter.lift, comap_iInf]`

Original:

```text
hyp: α : Type u_1
goal: comap m (Filter.lift f g) = Filter.lift f (comap m ∘ g)
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: comap pseudo_2 (Filter.lift pseudo_0 pseudo_1)  =  Filter.lift pseudo_0 (comap pseudo_2 ∘ pseudo_1)
```

## Example 23

- source proof id: `e23c9dcc-fade-4f73-9511-2f7a3bb4e7d2`
- pseudo proof id: `e23c9dcc-fade-4f73-9511-2f7a3bb4e7d2-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'F': 'pseudo_1', 'K': 'pseudo_2', 'L': 'pseudo_3', 'i': 'pseudo_4', 'f': 'pseudo_5', 'h': 'pseudo_6', 'e': 'pseudo_7'}`
- original proof step: `rw [← e.comp_algebraMap_of_tower R]`
- pseudo proof step: `rw [← pseudo_7.comp_algebraMap_of_tower pseudo_0]`

Original:

```text
hyp: R : Type u_1
goal: Splits (algebraMap R L) f
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: Splits
  (algebraMap pseudo_0 pseudo_3) pseudo_5
```

## Example 24

- source proof id: `8337b96a-cd0e-4e83-9481-ee7fa7450067`
- pseudo proof id: `8337b96a-cd0e-4e83-9481-ee7fa7450067-pseudo-local-rename-v1`
- rename map: `{'K': 'pseudo_0', 'V': 'pseudo_1'}`
- original proof step: `exact eval_ker K V`
- pseudo proof step: `exact eval_ker pseudo_0 pseudo_1`

Original:

```text
hyp: case hf
goal: ker (eval K V) = ⊥
```

Pseudo:

```text
hyp: case
  hf
goal: ker (eval pseudo_0 pseudo_1)  =  ⊥
```

## Example 25

- source proof id: `4678d6e3-3245-41e8-89a3-72ae4e50db7d`
- pseudo proof id: `4678d6e3-3245-41e8-89a3-72ae4e50db7d-pseudo-local-rename-v1`
- rename map: `{'V': 'pseudo_0', 'G': 'pseudo_1', 'P': 'pseudo_2', 'v': 'pseudo_3', '_h3': 'pseudo_4', 'h1': 'pseudo_5', 'h2': 'pseudo_6'}`
- original proof step: `obtain ⟨⟨h1, h2⟩, _h3⟩ := (P.isPartition.2 v).choose_spec`
- pseudo proof step: `obtain ⟨⟨pseudo_5, pseudo_6⟩, pseudo_4⟩ := (pseudo_2.isPartition.2 pseudo_3).choose_spec`

Original:

```text
hyp: V : Type u
goal: v ∈ partOfVertex P v
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: pseudo_3
  ∈ partOfVertex pseudo_2 pseudo_3
```

## Example 26

- source proof id: `8c728189-3abd-43c8-a86f-80fba796cdcd`
- pseudo proof id: `8c728189-3abd-43c8-a86f-80fba796cdcd-pseudo-local-rename-v1`
- rename map: `{'E': 'pseudo_0', 'F': 'pseudo_1', 's': 'pseudo_2', 'x': 'pseudo_3', 'h': 'pseudo_4', 't': 'pseudo_5', 'ht': 'pseudo_6', "h't": 'pseudo_7', "h''t": 'pseudo_8', 'r': 'pseudo_9'}`
- original proof step: `apply ENNReal.div_le_of_le_mul`
- pseudo proof step: `apply ENNReal.div_le_of_le_mul`

Original:

```text
hyp: case h
goal: ↑↑μ (toMeasurable μ s ∩ closedBall x r) / ↑↑μ (closedBall x r) ≤ 1
```

Pseudo:

```text
hyp: case
  pseudo_4
goal: ↑↑μ (toMeasurable μ pseudo_2 ∩ closedBall pseudo_3 pseudo_9)  /  ↑↑μ (closedBall pseudo_3 pseudo_9) ≤ 1
```

## Example 27

- source proof id: `a319884c-088b-4f0c-aecd-8e5b13c08c34`
- pseudo proof id: `a319884c-088b-4f0c-aecd-8e5b13c08c34-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'S': 'pseudo_1', 'M': 'pseudo_2', 'N': 'pseudo_3', "R'": 'pseudo_4', "S'": 'pseudo_5', 'f': 'pseudo_6', 'x': 'pseudo_7', 's': 'pseudo_8', 'g': 'pseudo_9', 'y': 'pseudo_10', "y'": 'pseudo_11', "hy'": 'pseudo_12', 'e': 'pseudo_13', 'this': 'pseudo_14', "x'": 'pseudo_15', "hx'": 'pseudo_16', "hx''": 'pseudo_17', 'a': 'pseudo_18'}`
- original proof step: `exact Algebra.smul_def _ _`
- pseudo proof step: `exact Algebra.smul_def _ _`

Original:

```text
hyp: case h.e'_2
goal: ↑{ val := a, property := ha₁ } • ↑{ val := y', property := hy' } • x = (algebraMap R S) a * y' • x
```

Pseudo:

```text
hyp: case
  h.e'_2
goal: ↑{ val := pseudo_18, property := ha₁ } • ↑{ val := pseudo_11, property := pseudo_12 } • pseudo_7  =  (algebraMap pseudo_0 pseudo_1) pseudo_18 * pseudo_11 • pseudo_7
```

## Example 28

- source proof id: `ab3c19a4-0a80-4d5f-a194-de2a0c418f73`
- pseudo proof id: `ab3c19a4-0a80-4d5f-a194-de2a0c418f73-pseudo-local-rename-v1`
- rename map: `{}`
- original proof step: `simp [Measure.prod_swap]`
- pseudo proof step: `simp [Measure.prod_swap]`

Original:

```text
hyp: case a
goal: ↑(map (prod μ ν) ⋯) = ↑(prod ν μ)
```

Pseudo:

```text
hyp: case
  a
goal: ↑(map (prod μ ν) ⋯)  =  ↑(prod ν μ)
```

## Example 29

- source proof id: `da0559d0-c20b-4d82-98bd-b899ce5b390b`
- pseudo proof id: `da0559d0-c20b-4d82-98bd-b899ce5b390b-pseudo-local-rename-v1`
- rename map: `{'m': 'pseudo_0', 'x': 'pseudo_1', 'hx': 'pseudo_2'}`
- original proof step: `rw [mem_Ioi] at hx`
- pseudo proof step: `rw [mem_Ioi] at pseudo_2`

Original:

```text
hyp: case hf''
goal: 0 < deriv^[2] (fun x => x ^ m) x
```

Pseudo:

```text
hyp: case
  hf''
goal: 0
  < deriv^[2] (fun pseudo_1 => pseudo_1 ^ pseudo_0) pseudo_1
```

## Example 30

- source proof id: `6304802b-70e0-4523-a882-44f20935f2ec`
- pseudo proof id: `6304802b-70e0-4523-a882-44f20935f2ec-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'K': 'pseudo_1', 'L': 'pseudo_2', 'M': 'pseudo_3', 'z': 'pseudo_4', 'hz': 'pseudo_5', 'hzc': 'pseudo_6', 'x': 'pseudo_7'}`
- original proof step: `rw [traceForm_apply_apply, LinearMap.zero_apply]`
- pseudo proof step: `rw [traceForm_apply_apply, LinearMap.zero_apply]`

Original:

```text
hyp: case intro.h
goal: ((traceForm R L M) z) x = 0 x
```

Pseudo:

```text
hyp: case
  intro.h
goal: ((traceForm pseudo_0 pseudo_2 pseudo_3) pseudo_4) pseudo_7  =  0 pseudo_7
```

## Example 31

- source proof id: `106dddc8-5e64-4bef-acc5-40d96cdcc043`
- pseudo proof id: `106dddc8-5e64-4bef-acc5-40d96cdcc043-pseudo-local-rename-v1`
- rename map: `{'X': 'pseudo_0', 'Y': 'pseudo_1', 'Z': 'pseudo_2', 'f': 'pseudo_3', 'g': 'pseudo_4', 'hf': 'pseudo_5'}`
- original proof step: `rw [comap, dif_pos hf]`
- pseudo proof step: `rw [comap, dif_pos pseudo_5]`

Original:

```text
hyp: X : Type u_1
goal: ⇑(comap f g) = ⇑g ∘ f
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: ⇑(comap pseudo_3 pseudo_4)  =  ⇑pseudo_4 ∘ pseudo_3
```

## Example 32

- source proof id: `b54900fb-5933-42d3-a0ea-b76d13ea6761`
- pseudo proof id: `b54900fb-5933-42d3-a0ea-b76d13ea6761-pseudo-local-rename-v1`
- rename map: `{'M': 'pseudo_0', 'S': 'pseudo_1', 'N': 'pseudo_2', 'P': 'pseudo_3', 'f': 'pseudo_4', 'h': 'pseudo_5', 'fl': 'pseudo_6', 'g': 'pseudo_7'}`
- original proof step: `let g := f.toMap`
- pseudo proof step: `let pseudo_7 := pseudo_4.toMap`

Original:

```text
hyp: M : Type u_1
goal: IsLeftCancelMulZero N
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: IsLeftCancelMulZero
  pseudo_2
```

## Example 33

- source proof id: `0e83738c-da43-4681-98b7-f8aa1a31de6e`
- pseudo proof id: `0e83738c-da43-4681-98b7-f8aa1a31de6e-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'X': 'pseudo_1', 'Y': 'pseudo_2', 'f': 'pseudo_3'}`
- original proof step: `ext`
- pseudo proof step: `ext`

Original:

```text
hyp: C : Type u
goal: biprod.desc f 0 = biprod.fst ≫ f
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: biprod.desc pseudo_3 0  =  biprod.fst ≫ pseudo_3
```

## Example 34

- source proof id: `be2ea45a-02ef-446d-9d61-571cbd12932a`
- pseudo proof id: `be2ea45a-02ef-446d-9d61-571cbd12932a-pseudo-local-rename-v1`
- rename map: `{'V': 'pseudo_0', 'P': 'pseudo_1', 's': 'pseudo_2', 'ps': 'pseudo_3', 'hnps': 'pseudo_4', 'p': 'pseudo_5', 'hps': 'pseudo_6', 'hp': 'pseudo_7', 'this': 'pseudo_8', 'cc': 'pseudo_9', 'cr': 'pseudo_10', 'hcccru': 'pseudo_11', 'hcc': 'pseudo_12', 'hcr': 'pseudo_13', 'x': 'pseudo_14', 'y': 'pseudo_15', 'hy0': 'pseudo_16', 'hpo': 'pseudo_17'}`
- original proof step: `have hpo : p = (1 : ℝ) • (p -ᵥ orthogonalProjection s p : V) +ᵥ (orthogonalProjection s p : P) :=
  by simp`
- pseudo proof step: `have pseudo_17 : pseudo_5 = (1 : ℝ) • (pseudo_5 -ᵥ orthogonalProjection pseudo_2 pseudo_5 : pseudo_0) +ᵥ (orthogonalProjection pseudo_2 pseudo_5 : pseudo_1) :=
  by simp`

Original:

```text
hyp: case h
goal: ({ center := cc₂, radius := cr₂ }.center ∈ affineSpan ℝ (insert p ↑s) ∧
      insert p ps ⊆ Metric.sphere { center := cc₂, radius := cr₂ }.center { center := cc₂, radius := cr₂ }.radius) ∧
    ∀ (y : Sphere P),
      y.center ∈ affineSpan ℝ
```

Pseudo:

```text
hyp: case
  h
goal: ({ center := pseudo_9₂, radius := pseudo_10₂ }.center ∈ affineSpan ℝ (insert pseudo_5 ↑pseudo_2) ∧
        insert pseudo_5 pseudo_3 ⊆ Metric.sphere { center := pseudo_9₂, radius := pseudo_10₂ }.center { center := pseudo_9₂, radius := pseudo
```

## Example 35

- source proof id: `3d317f2d-aead-4da5-b4af-f4997aea28b7`
- pseudo proof id: `3d317f2d-aead-4da5-b4af-f4997aea28b7-pseudo-local-rename-v1`
- rename map: `{'X': 'pseudo_0', 'a': 'pseudo_1', 'x': 'pseudo_2', 'y': 'pseudo_3', 'hxy': 'pseudo_4'}`
- original proof step: `exact eq_of_heq (Sigma.ext_iff.mp hxy).2`
- pseudo proof step: `exact eq_of_heq (Sigma.ext_iff.mp pseudo_4).2`

Original:

```text
hyp: α : Type
goal: x = y
```

Pseudo:

```text
hyp: α  :  Type
goal: pseudo_2  =  pseudo_3
```

## Example 36

- source proof id: `3e39c523-668d-48c5-9f11-6cd1431b786e`
- pseudo proof id: `3e39c523-668d-48c5-9f11-6cd1431b786e-pseudo-local-rename-v1`
- rename map: `{'K': 'pseudo_0', 'n': 'pseudo_1', 'g': 'pseudo_2', 's': 'pseudo_3', 'm': 'pseudo_4', 'm_lt_n': 'pseudo_5'}`
- original proof step: `cases s_succ_nth_eq : s.get? (n + 1) with
| none => rw [squashSeq_eq_self_of_terminated s_succ_nth_eq]
| some =>
  obtain ⟨gp_n, s_nth_eq⟩ : ∃ gp_n, s.get? n = some gp_n :=
    s.ge_stable n.le_succ s_succ_nth_eq
  obtain ⟨gp_m, s_mth_eq⟩ : ∃ gp_m, s.get? m = some gp_m :=
    s.ge_stable (le_of_lt m_lt_n) s_nth_eq
  simp [*, squashSeq, m_lt_n.ne]`
- pseudo proof step: `cases s_succ_nth_eq : pseudo_3.get? (pseudo_1 + 1) with
| none => rw [squashSeq_eq_self_of_terminated s_succ_nth_eq]
| some =>
  obtain ⟨gp_n, s_nth_eq⟩ : ∃ gp_n, pseudo_3.get? pseudo_1 = some gp_n :=
    pseudo_3.ge_stable pseudo_1.le_succ s_succ_nth_eq
  obtain ⟨gp_m, s_mth_eq⟩ : ∃ gp_m, pseudo_3.get? pseudo_4 = some gp_m :=
    pseudo_3.ge_stable (le_of_lt pseudo_5) s_nth_eq
  simp [*, squashSeq, pseudo_5.ne]`

Original:

```text
hyp: K : Type u_1
goal: Stream'.Seq.get? (squashSeq s n) m = Stream'.Seq.get? s m
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: Stream'.Seq.get? (squashSeq pseudo_3 pseudo_1) pseudo_4  =  Stream'.Seq.get? pseudo_3 pseudo_4
```

## Example 37

- source proof id: `69087947-0d4d-43e6-8720-94b7a5f54924`
- pseudo proof id: `69087947-0d4d-43e6-8720-94b7a5f54924-pseudo-local-rename-v1`
- rename map: `{'C': 'pseudo_0', 'D': 'pseudo_1', 'A': 'pseudo_2', 'S': 'pseudo_3'}`
- original proof step: `simp only [Abelian.exact_iff, S.zero,
  S.exact_iff_kernel_ι_comp_cokernel_π_zero, true_and]`
- pseudo proof step: `simp only [Abelian.exact_iff, pseudo_3.zero,
  pseudo_3.exact_iff_kernel_ι_comp_cokernel_π_zero, true_and]`

Original:

```text
hyp: C : Type u_1
goal: CategoryTheory.Exact S.f S.g ↔ Exact S
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: CategoryTheory.Exact
  pseudo_3.f pseudo_3.g ↔ Exact pseudo_3
```

## Example 38

- source proof id: `1fdbfbdf-805f-484f-afa7-8f879d493bbe`
- pseudo proof id: `1fdbfbdf-805f-484f-afa7-8f879d493bbe-pseudo-local-rename-v1`
- rename map: `{'E': 'pseudo_0', 'p': 'pseudo_1', 'hp': 'pseudo_2', 's': 'pseudo_3', 'u': 'pseudo_4', 's_closed': 'pseudo_5', 'u_open': 'pseudo_6', 'hsu': 'pseudo_7', 'hs': 'pseudo_8', 'c': 'pseudo_9', 'V': 'pseudo_10', 'sV': 'pseudo_11', 'V_open': 'pseudo_12', "h'V": 'pseudo_13', 'hV': 'pseudo_14', 'v': 'pseudo_15', 'hsv': 'pseudo_16', 'g': 'pseudo_17', 'hgv': 'pseudo_18', 'hgs': 'pseudo_19', 'hg_range': 'pseudo_20', 'g_norm': 'pseudo_21', 'gc_bd0': 'pseudo_22', 'gc_bd': 'pseudo_23'}`
- original proof step: `simp only [hgv hx, Pi.zero_apply, zero_smul]`
- pseudo proof step: `simp only [pseudo_18 hx, Pi.zero_apply, zero_smul]`

Original:

```text
hyp: α : Type u_1
goal: g x • c = 0
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: pseudo_17 x • pseudo_9  =  0
```

## Example 39

- source proof id: `7d7b3c90-80fd-44ef-a17e-3decd4df37fb`
- pseudo proof id: `7d7b3c90-80fd-44ef-a17e-3decd4df37fb-pseudo-local-rename-v1`
- rename map: `{'n': 'pseudo_0'}`
- original proof step: `simp only [show (4 : ℝ) = (2 : ℝ) ^ 2 by norm_num, mul_one]`
- pseudo proof step: `simp only [show (4 : ℝ) = (2 : ℝ) ^ 2 by norm_num, mul_one]`

Original:

```text
hyp: case refine'_2
goal: 4 ≤ 2 ^ (n + 2) * 1
```

Pseudo:

```text
hyp: case
  refine'_2
goal: 4 ≤ 2 ^ (pseudo_0  +  2) * 1
```

## Example 40

- source proof id: `6270aada-77f5-4476-b15e-ca0ba586e36f`
- pseudo proof id: `6270aada-77f5-4476-b15e-ca0ba586e36f-pseudo-local-rename-v1`
- rename map: `{'n': 'pseudo_0', 'S': 'pseudo_1', 'T': 'pseudo_2', 'A': 'pseudo_3', 'B': 'pseudo_4', 'K': 'pseudo_5', 'L': 'pseudo_6', 'hprim': 'pseudo_7', 't': 'pseudo_8', 'ht': 'pseudo_9'}`
- original proof step: `exact mod_cast hζ.unique (IsPrimitiveRoot.of_subsingleton ζ)`
- pseudo proof step: `exact mod_cast hζ.unique (IsPrimitiveRoot.of_subsingleton ζ)`

Original:

```text
hyp: case mp.mk.intro
goal: ↑t = 1
```

Pseudo:

```text
hyp: case
  mp.mk.intro
goal: ↑pseudo_8  =  1
```

## Example 41

- source proof id: `36c4db51-5ddf-42b0-9d0d-dbbc2e327641`
- pseudo proof id: `36c4db51-5ddf-42b0-9d0d-dbbc2e327641-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'K': 'pseudo_1', 'v': 'pseudo_2', 'I': 'pseudo_3', 'hI': 'pseudo_4'}`
- original proof step: `rw [mulSupport]`
- pseudo proof step: `rw [mulSupport]`

Original:

```text
hyp: R : Type u_1
goal: Set.Finite
    (mulSupport fun v =>
      ↑v.asIdeal ^ ↑(Associates.count (Associates.mk v.asIdeal) (Associates.factors (Associates.mk I))))
```

Pseudo:

```text
hyp: pseudo_0  :  Type u_1
goal: Set.Finite
      (mulSupport fun pseudo_2 =>
        ↑pseudo_2.asIdeal ^ ↑(Associates.count (Associates.mk pseudo_2.asIdeal) (Associates.factors (Associates.mk pseudo_3))))
```

## Example 42

- source proof id: `512a129a-9b4e-4dbd-8812-f265054ec877`
- pseudo proof id: `512a129a-9b4e-4dbd-8812-f265054ec877-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'J': 'pseudo_1', 'K': 'pseudo_2', 'L': 'pseudo_3', 'I': 'pseudo_4', 'r': 'pseudo_5', 'hr': 'pseudo_6', 'hri': 'pseudo_7', 'hrm': 'pseudo_8', 'him': 'pseudo_9', 'hm': 'pseudo_10', 'this': 'pseudo_11'}`
- original proof step: `exact hrm trivial`
- pseudo proof step: `exact pseudo_8 trivial`

Original:

```text
hyp: R : Type u
goal: False
```

Pseudo:

```text
hyp: pseudo_0  :  Type u
goal: False

```

## Example 43

- source proof id: `0f64adc5-ed8e-490b-9e13-903b129ba8b3`
- pseudo proof id: `0f64adc5-ed8e-490b-9e13-903b129ba8b3-pseudo-local-rename-v1`
- rename map: `{'Fq': 'pseudo_0', 'd': 'pseudo_1', 'm': 'pseudo_2', 'hm': 'pseudo_3', 'b': 'pseudo_4', 'A': 'pseudo_5', 'hA': 'pseudo_6', 'hb': 'pseudo_7', 'f': 'pseudo_8', 'this': 'pseudo_9', 'i_ne': 'pseudo_10', 'i_eq': 'pseudo_11', 'j': 'pseudo_12', 'hbj': 'pseudo_13', 'hj': 'pseudo_14'}`
- original proof step: `have : j = b.natDegree - (natDegree b - j.succ).succ := by
  rw [← Nat.succ_sub hbj, Nat.succ_sub_succ, tsub_tsub_cancel_of_le hbj.le]`
- pseudo proof step: `have : pseudo_12 = pseudo_4.natDegree - (natDegree pseudo_4 - pseudo_12.succ).succ := by
  rw [← Nat.succ_sub pseudo_13, Nat.succ_sub_succ, tsub_tsub_cancel_of_le pseudo_13.le]`

Original:

```text
hyp: case neg
goal: coeff (A i₁) j = coeff (A i₀) j
```

Pseudo:

```text
hyp: case
  neg
goal: coeff (pseudo_5 i₁) pseudo_12  =  coeff (pseudo_5 i₀) pseudo_12
```

## Example 44

- source proof id: `5a960258-cae6-4f73-a647-6a8da21d3342`
- pseudo proof id: `5a960258-cae6-4f73-a647-6a8da21d3342-pseudo-local-rename-v1`
- rename map: `{'f': 'pseudo_0', 'hf': 'pseudo_1', 'this': 'pseudo_2', 'a': 'pseudo_3'}`
- original proof step: `simp`
- pseudo proof step: `simp`

Original:

```text
hyp: α : Type u_1
goal: (Nat.casesOn (encode (decode a.2)) (Part.some Option.none) fun n => map (f a.1) ↑(decode n)) =
    (↑fun p => (fun a n => Option.bind (decode n) (f a)) p.1 p.2) a
```

Pseudo:

```text
hyp: α  :  Type u_1
goal: (Nat.casesOn (encode (decode pseudo_3.2)) (Part.some Option.none) fun n => map (pseudo_0 pseudo_3.1) ↑(decode n)) =
      (↑fun p => (fun pseudo_3 n => Option.bind (decode n) (pseudo_0 pseudo_3)) p.1 p.2) pseudo_3
```

## Example 45

- source proof id: `3581e3e6-1b15-4e02-bbf2-58bfc908969d`
- pseudo proof id: `3581e3e6-1b15-4e02-bbf2-58bfc908969d-pseudo-local-rename-v1`
- rename map: `{'E': 'pseudo_0', 'F': 'pseudo_1', 'f': 'pseudo_2', 'surj': 'pseudo_3', 's': 'pseudo_4', 'hs': 'pseudo_5', 'C': 'pseudo_6', 'Cpos': 'pseudo_7', 'hC': 'pseudo_8', 'y': 'pseudo_9', 'yfs': 'pseudo_10', 'x': 'pseudo_11', 'xs': 'pseudo_12', 'fxy': 'pseudo_13', 'z': 'pseudo_14', 'hz': 'pseudo_15', 'w': 'pseudo_16', 'wim': 'pseudo_17', 'wnorm': 'pseudo_18', 'this': 'pseudo_19'}`
- original proof step: `rwa [mem_ball, dist_eq_norm] at hz`
- pseudo proof step: `rwa [mem_ball, dist_eq_norm] at pseudo_15`

Original:

```text
hyp: 𝕜 : Type u_1
goal: ‖z - y‖ < ε / C
```

Pseudo:

```text
hyp: 𝕜  :  Type u_1
goal: ‖pseudo_14  -  pseudo_9‖ < ε / pseudo_6
```

## Example 46

- source proof id: `16201d2d-6b5f-4651-93be-c8d311d53c59`
- pseudo proof id: `16201d2d-6b5f-4651-93be-c8d311d53c59-pseudo-local-rename-v1`
- rename map: `{'z': 'pseudo_0', 'h': 'pseudo_1'}`
- original proof step: `rwa [← div_lt_iff' two_pos, neg_div]`
- pseudo proof step: `rwa [← div_lt_iff' two_pos, neg_div]`

Original:

```text
hyp: case hx₁
goal: -π < 2 * z.re
```

Pseudo:

```text
hyp: case
  hx₁
goal: -π < 2  *  pseudo_0.re
```

## Example 47

- source proof id: `710f614d-a31b-4d09-a5ce-dc0b90f65908`
- pseudo proof id: `710f614d-a31b-4d09-a5ce-dc0b90f65908-pseudo-local-rename-v1`
- rename map: `{'B': 'pseudo_0', 'x': 'pseudo_1', 'h': 'pseudo_2'}`
- original proof step: `obtain ⟨h₁ : x ∈ e₁.baseSet, h₂ : x ∈ e₂.baseSet⟩ := h`
- pseudo proof step: `obtain ⟨pseudo_2₁ : pseudo_1 ∈ e₁.baseSet, pseudo_2₂ : pseudo_1 ∈ e₂.baseSet⟩ := pseudo_2`

Original:

```text
hyp: case mk.mk
goal: invFun' e₁ e₂ (toFun' e₁ e₂ { proj := x, snd := (v₁, v₂) }) = { proj := x, snd := (v₁, v₂) }
```

Pseudo:

```text
hyp: case
  mk.mk
goal: invFun' e₁ e₂ (toFun' e₁ e₂ { proj := pseudo_1, snd := (v₁, v₂) })  =  { proj := pseudo_1, snd := (v₁, v₂) }
```

## Example 48

- source proof id: `aff88042-b2b3-486e-bfbf-a7e4a1de3a9b`
- pseudo proof id: `aff88042-b2b3-486e-bfbf-a7e4a1de3a9b-pseudo-local-rename-v1`
- rename map: `{'R': 'pseudo_0', 'B': 'pseudo_1', 'F': 'pseudo_2', 'E': 'pseudo_3', 'e': 'pseudo_4', 'b': 'pseudo_5', 'hb': 'pseudo_6', 'z': 'pseudo_7', 'h': 'pseudo_8'}`
- original proof step: `simp_rw [e.right_inv h, coe_coe, e.apply_eq_prod_continuousLinearEquivAt R b hb,
  ContinuousLinearEquiv.apply_symm_apply]`
- pseudo proof step: `simp_rw [pseudo_4.right_inv pseudo_8, coe_coe, pseudo_4.apply_eq_prod_continuousLinearEquivAt pseudo_0 pseudo_5 pseudo_6,
  ContinuousLinearEquiv.apply_symm_apply]`

Original:

```text
hyp: case a
goal: ↑e.toPartialHomeomorph (↑(PartialHomeomorph.symm e.toPartialHomeomorph) (b, z)) =
    ↑e.toPartialHomeomorph { proj := b, snd := (ContinuousLinearEquiv.symm (continuousLinearEquivAt R e b hb)) z }
```

Pseudo:

```text
hyp: case
  a
goal: ↑pseudo_4.toPartialHomeomorph (↑(PartialHomeomorph.symm pseudo_4.toPartialHomeomorph) (pseudo_5, pseudo_7)) =
      ↑pseudo_4.toPartialHomeomorph { proj := pseudo_5, snd := (ContinuousLinearEquiv.symm (continuousLinearEquivAt pseudo_0 pseud
```

## Example 49

- source proof id: `09d0164b-4bbe-409a-8ca7-2a59579e57f9`
- pseudo proof id: `09d0164b-4bbe-409a-8ca7-2a59579e57f9-pseudo-local-rename-v1`
- rename map: `{'m': 'pseudo_0', 'x': 'pseudo_1', 'y': 'pseudo_2', 'i': 'pseudo_3'}`
- original proof step: `simp only [eq_comm, Finset.mem_filter, Multiset.mem_toEnumFinset, Finset.mem_map,
  Finset.mem_range, Function.Embedding.coeFn_mk, Prod.mk.inj_iff, exists_prop,
  exists_eq_right_right', and_congr_left_iff]`
- pseudo proof step: `simp only [eq_comm, Finset.mem_filter, Multiset.mem_toEnumFinset, Finset.mem_map,
  Finset.mem_range, Function.Embedding.coeFn_mk, Prod.mk.inj_iff, exists_prop,
  exists_eq_right_right', and_congr_left_iff]`

Original:

```text
hyp: case a.mk
goal: (y, i) ∈ Finset.filter (fun p => x = p.1) (toEnumFinset m) ↔
    (y, i) ∈ Finset.map { toFun := Prod.mk x, inj' := ⋯ } (Finset.range (count x m))
```

Pseudo:

```text
hyp: case
  a.mk
goal: (pseudo_2, pseudo_3) ∈ Finset.filter (fun p => pseudo_1  =  p.1) (toEnumFinset pseudo_0) ↔
      (pseudo_2, pseudo_3) ∈ Finset.map { toFun := Prod.mk pseudo_1, inj' := ⋯ } (Finset.range (count pseudo_1 pseudo_0))
```

## Example 50

- source proof id: `55ec4dca-5f0d-4147-b45c-78acb9e3b704`
- pseudo proof id: `55ec4dca-5f0d-4147-b45c-78acb9e3b704-pseudo-local-rename-v1`
- rename map: `{'a': 'pseudo_0', 'b': 'pseudo_1', 'c': 'pseudo_2', 'd': 'pseudo_3', 'e': 'pseudo_4', 'm': 'pseudo_5', 'n': 'pseudo_6', 'h': 'pseudo_7', 'hc': 'pseudo_8'}`
- original proof step: `rwa [mul_comm b, ← div_le_iff hc]`
- pseudo proof step: `rwa [mul_comm pseudo_1, ← div_le_iff pseudo_8]`

Original:

```text
hyp: ι : Type u_1
goal: b * a ≤ d * c
```

Pseudo:

```text
hyp: ι  :  Type u_1
goal: pseudo_1  *  pseudo_0 ≤ pseudo_3 * pseudo_2
```
