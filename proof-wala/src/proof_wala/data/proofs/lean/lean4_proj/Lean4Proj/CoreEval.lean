namespace core_eval

theorem n_plus_zero (n : Nat) : n + 0 = n := by
  sorry

theorem n_plus_succ (n m : Nat) : n + Nat.succ m = Nat.succ (n + m) := by
  sorry

theorem n_zero_plus (n : Nat) : 0 + n = n := by
  sorry

theorem n_succ_plus (n m : Nat) : Nat.succ n + m = Nat.succ (n + m) := by
  sorry

theorem n_mod_2_implies_square_mod (n : Nat) :
    n % 2 = 0 -> n * n % 2 = 0 := by
  sorry

theorem prop_true : True := by
  sorry

theorem prop_id (p : Prop) (hp : p) : p := by
  sorry

theorem prop_and_intro (p q : Prop) (hp : p) (hq : q) : And p q := by
  sorry

theorem prop_and_left (p q : Prop) (h : And p q) : p := by
  sorry

theorem prop_and_right (p q : Prop) (h : And p q) : q := by
  sorry

theorem prop_imp_self_001 (p : Prop) : p -> p := by
  sorry

theorem prop_imp_self_002 (p : Prop) (hp : p) : p := by
  sorry

theorem prop_imp_trans_003 (p q r : Prop) (hpq : p -> q) (hqr : q -> r) (hp : p) : r := by
  sorry

theorem prop_imp_swap_004 (p q : Prop) (hq : q) : p -> q := by
  sorry

theorem prop_imp_const_005 (p q : Prop) (hp : p) : q -> p := by
  sorry

theorem prop_imp_apply_006 (p q : Prop) (h : p -> q) (hp : p) : q := by
  sorry

theorem prop_imp_apply_007 (p q r : Prop) (h : p -> q -> r) (hp : p) (hq : q) : r := by
  sorry

theorem prop_imp_apply_008 (p q r : Prop) (h : q -> p -> r) (hp : p) (hq : q) : r := by
  sorry

theorem prop_imp_chain_009 (p q r s : Prop) (hpq : p -> q) (hqr : q -> r) (hrs : r -> s) (hp : p) : s := by
  sorry

theorem prop_imp_chain_010 (p q r : Prop) (hpr : p -> r) (hp : p) : q -> r := by
  sorry

theorem prop_imp_chain_011 (p q r : Prop) (hqr : q -> r) (hq : q) : p -> r := by
  sorry

theorem prop_imp_chain_012 (p q : Prop) (h : p -> q) : p -> q := by
  sorry

theorem prop_imp_chain_013 (p q : Prop) (h : p) : q -> p := by
  sorry

theorem prop_imp_chain_014 (p q : Prop) (h : q) : p -> q := by
  sorry

theorem prop_imp_chain_015 (p q r : Prop) (hp : p) (h : p -> q -> r) : q -> r := by
  sorry

theorem and_comm_016 (p q : Prop) (h : And p q) : And q p := by
  sorry

theorem and_assoc_left_017 (p q r : Prop) (h : And (And p q) r) : And p (And q r) := by
  sorry

theorem and_assoc_right_018 (p q r : Prop) (h : And p (And q r)) : And (And p q) r := by
  sorry

theorem and_left_id_019 (p : Prop) (h : And True p) : p := by
  sorry

theorem and_right_id_020 (p : Prop) (h : And p True) : p := by
  sorry

theorem and_intro_true_left_021 (p : Prop) (hp : p) : And True p := by
  sorry

theorem and_intro_true_right_022 (p : Prop) (hp : p) : And p True := by
  sorry

theorem and_dup_intro_023 (p : Prop) (hp : p) : And p p := by
  sorry

theorem and_dup_left_024 (p : Prop) (h : And p p) : p := by
  sorry

theorem and_dup_right_025 (p : Prop) (h : And p p) : p := by
  sorry

theorem and_project_026 (p q r : Prop) (h : And p (And q r)) : q := by
  sorry

theorem and_project_027 (p q r : Prop) (h : And p (And q r)) : r := by
  sorry

theorem and_project_028 (p q r : Prop) (h : And (And p q) r) : p := by
  sorry

theorem and_project_029 (p q r : Prop) (h : And (And p q) r) : q := by
  sorry

theorem and_project_030 (p q r : Prop) (h : And (And p q) r) : r := by
  sorry

theorem and_reorder_031 (p q r : Prop) (h : And p (And q r)) : And r (And q p) := by
  sorry

theorem and_reorder_032 (p q r : Prop) (h : And (And p q) r) : And q (And r p) := by
  sorry

theorem and_reorder_033 (p q r s : Prop) (h : And (And p q) (And r s)) : And p s := by
  sorry

theorem and_reorder_034 (p q r s : Prop) (h : And (And p q) (And r s)) : And q r := by
  sorry

theorem and_reorder_035 (p q r s : Prop) (h : And (And p q) (And r s)) : And s p := by
  sorry

theorem and_reorder_036 (p q r s : Prop) (h : And p (And q (And r s))) : And s (And r (And q p)) := by
  sorry

theorem and_reorder_037 (p q r s : Prop) (h : And (And (And p q) r) s) : And p (And q (And r s)) := by
  sorry

theorem and_reorder_038 (p q : Prop) (hp : p) (hq : q) : And q p := by
  sorry

theorem and_reorder_039 (p q r : Prop) (hp : p) (hq : q) (hr : r) : And r (And p q) := by
  sorry

theorem and_reorder_040 (p q r : Prop) (hp : p) (hq : q) (hr : r) : And (And q r) p := by
  sorry

theorem or_inl_041 (p q : Prop) (hp : p) : Or p q := by
  sorry

theorem or_inr_042 (p q : Prop) (hq : q) : Or p q := by
  sorry

theorem or_comm_043 (p q : Prop) (h : Or p q) : Or q p := by
  sorry

theorem or_assoc_left_044 (p q r : Prop) (h : Or (Or p q) r) : Or p (Or q r) := by
  sorry

theorem or_assoc_right_045 (p q r : Prop) (h : Or p (Or q r)) : Or (Or p q) r := by
  sorry

theorem or_elim_046 (p q r : Prop) (h : Or p q) (hp : p -> r) (hq : q -> r) : r := by
  sorry

theorem or_left_true_047 (p : Prop) : Or True p := by
  sorry

theorem or_right_true_048 (p : Prop) : Or p True := by
  sorry

theorem or_dup_intro_049 (p : Prop) (hp : p) : Or p p := by
  sorry

theorem or_dup_elim_050 (p : Prop) (h : Or p p) : p := by
  sorry

theorem or_and_distrib_051 (p q r : Prop) (h : And (Or p q) r) : Or (And p r) (And q r) := by
  sorry

theorem or_and_distrib_052 (p q r : Prop) (h : And p (Or q r)) : Or (And p q) (And p r) := by
  sorry

theorem or_case_left_053 (p q r : Prop) (hp : p) : Or (And p q) (And p r) -> p := by
  sorry

theorem or_case_right_054 (p q r : Prop) (hr : r) : Or p q -> Or p r := by
  sorry

theorem or_case_project_055 (p q r : Prop) (h : Or (And p r) (And q r)) : r := by
  sorry

theorem or_case_project_056 (p q r : Prop) (h : Or (And p q) (And p r)) : p := by
  sorry

theorem or_swap_nested_057 (p q r : Prop) (h : Or p (Or q r)) : Or r (Or q p) := by
  sorry

theorem or_swap_nested_058 (p q r : Prop) (h : Or (Or p q) r) : Or q (Or r p) := by
  sorry

theorem or_from_and_left_059 (p q r : Prop) (h : And p q) : Or p r := by
  sorry

theorem or_from_and_right_060 (p q r : Prop) (h : And p q) : Or r q := by
  sorry

theorem or_elim_to_and_061 (p q r : Prop) (h : Or p q) (hp : p -> r) (hq : q -> r) : And r r := by
  sorry

theorem or_elim_to_or_062 (p q r : Prop) (h : Or p q) : Or (Or p r) (Or q r) := by
  sorry

theorem or_elim_to_or_063 (p q r : Prop) (h : Or p q) : Or (Or r p) (Or r q) := by
  sorry

theorem or_elim_to_imp_064 (p q r : Prop) (h : Or p q) (hp : p -> r) (hq : q -> r) : True := by
  sorry

theorem or_elim_to_true_065 (p q : Prop) (h : Or p q) : True := by
  sorry

theorem iff_refl_066 (p : Prop) : Iff p p := by
  sorry

theorem iff_symm_067 (p q : Prop) (h : Iff p q) : Iff q p := by
  sorry

theorem iff_trans_068 (p q r : Prop) (hpq : Iff p q) (hqr : Iff q r) : Iff p r := by
  sorry

theorem iff_mp_069 (p q : Prop) (h : Iff p q) (hp : p) : q := by
  sorry

theorem iff_mpr_070 (p q : Prop) (h : Iff p q) (hq : q) : p := by
  sorry

theorem iff_true_intro_071 (p : Prop) (hp : p) : Iff p True := by
  sorry

theorem iff_true_intro_072 (p : Prop) (hp : p) : Iff True p := by
  sorry

theorem iff_and_comm_073 (p q : Prop) : Iff (And p q) (And q p) := by
  sorry

theorem iff_or_comm_074 (p q : Prop) : Iff (Or p q) (Or q p) := by
  sorry

theorem iff_imp_and_075 (p q : Prop) : Iff (And p q) (And q p) := by
  sorry

theorem iff_imp_or_076 (p q : Prop) : Iff (Or p q) (Or q p) := by
  sorry

theorem iff_and_true_left_077 (p : Prop) : Iff (And True p) p := by
  sorry

theorem iff_and_true_right_078 (p : Prop) : Iff (And p True) p := by
  sorry

theorem iff_or_false_left_079 (p : Prop) : Iff (Or False p) p := by
  sorry

theorem iff_or_false_right_080 (p : Prop) : Iff (Or p False) p := by
  sorry

theorem iff_and_assoc_081 (p q r : Prop) : Iff (And (And p q) r) (And p (And q r)) := by
  sorry

theorem iff_or_assoc_082 (p q r : Prop) : Iff (Or (Or p q) r) (Or p (Or q r)) := by
  sorry

theorem iff_dup_and_083 (p : Prop) : Iff (And p p) p := by
  sorry

theorem iff_dup_or_084 (p : Prop) : Iff (Or p p) p := by
  sorry

theorem iff_imp_self_085 (p : Prop) : Iff (p -> p) True := by
  sorry

theorem false_elim_086 (p : Prop) (h : False) : p := by
  sorry

theorem not_intro_087 (p : Prop) (h : p -> False) : Not p := by
  sorry

theorem not_elim_088 (p : Prop) (hn : Not p) (hp : p) : False := by
  sorry

theorem not_false_089 : Not False := by
  sorry

theorem false_imp_090 (p : Prop) : False -> p := by
  sorry

theorem not_not_intro_091 (p : Prop) (hp : p) : Not (Not p) := by
  sorry

theorem contradiction_to_true_092 (p : Prop) (hp : p) (hn : Not p) : True := by
  sorry

theorem contradiction_to_false_093 (p : Prop) (hp : p) (hn : Not p) : False := by
  sorry

theorem not_and_left_094 (p q : Prop) (hn : Not p) : Not (And p q) := by
  sorry

theorem not_and_right_095 (p q : Prop) (hn : Not q) : Not (And p q) := by
  sorry

theorem not_or_intro_096 (p q : Prop) (hp : Not p) (hq : Not q) : Not (Or p q) := by
  sorry

theorem not_imp_false_097 (p : Prop) (h : Not p) : p -> False := by
  sorry

theorem not_true_to_false_098 (h : Not True) : False := by
  sorry

theorem false_and_left_099 (p : Prop) (h : And False p) : False := by
  sorry

theorem false_and_right_100 (p : Prop) (h : And p False) : False := by
  sorry

theorem eq_refl_nat_101 (n : Nat) : n = n := by
  sorry

theorem eq_refl_bool_102 (b : Bool) : b = b := by
  sorry

theorem eq_refl_prop_103 (p : Prop) : p = p := by
  sorry

theorem eq_symm_nat_104 (n m : Nat) (h : n = m) : m = n := by
  sorry

theorem eq_trans_nat_105 (a b c : Nat) (hab : a = b) (hbc : b = c) : a = c := by
  sorry

theorem eq_subst_nat_106 (a b : Nat) (h : a = b) : a + 0 = b + 0 := by
  sorry

theorem eq_subst_nat_107 (a b : Nat) (h : a = b) : Nat.succ a = Nat.succ b := by
  sorry

theorem eq_subst_nat_108 (a b c : Nat) (h : a = b) : a + c = b + c := by
  sorry

theorem eq_subst_nat_109 (a b c : Nat) (h : a = b) : c + a = c + b := by
  sorry

theorem eq_subst_nat_110 (a b c : Nat) (h : a = b) : a * c = b * c := by
  sorry

theorem eq_subst_nat_111 (a b c : Nat) (h : a = b) : c * a = c * b := by
  sorry

theorem eq_pair_112 (a b : Nat) : (a, b) = (a, b) := by
  sorry

theorem eq_pair_fst_113 (a b : Nat) : (a, b).1 = a := by
  sorry

theorem eq_pair_snd_114 (a b : Nat) : (a, b).2 = b := by
  sorry

theorem eq_option_none_115 : (none : Option Nat) = none := by
  sorry

theorem eq_option_some_116 (n : Nat) : some n = (some n : Option Nat) := by
  sorry

theorem eq_list_nil_117 : ([] : List Nat) = [] := by
  sorry

theorem eq_list_cons_118 (n : Nat) (xs : List Nat) : n :: xs = n :: xs := by
  sorry

theorem eq_list_append_nil_119 (xs : List Nat) : xs ++ [] = xs := by
  sorry

theorem eq_list_nil_append_120 (xs : List Nat) : [] ++ xs = xs := by
  sorry

theorem eq_bool_true_121 : true = true := by
  sorry

theorem eq_bool_false_122 : false = false := by
  sorry

theorem eq_if_true_123 (a b : Nat) : (if true then a else b) = a := by
  sorry

theorem eq_if_false_124 (a b : Nat) : (if false then a else b) = b := by
  sorry

theorem eq_heq_simple_125 (n : Nat) : HEq n n := by
  sorry

theorem nat_zero_add_126 (n : Nat) : 0 + n = n := by
  sorry

theorem nat_add_zero_127 (n : Nat) : n + 0 = n := by
  sorry

theorem nat_one_mul_128 (n : Nat) : 1 * n = n := by
  sorry

theorem nat_mul_one_129 (n : Nat) : n * 1 = n := by
  sorry

theorem nat_zero_mul_130 (n : Nat) : 0 * n = 0 := by
  sorry

theorem nat_mul_zero_131 (n : Nat) : n * 0 = 0 := by
  sorry

theorem nat_add_succ_132 (n m : Nat) : n + Nat.succ m = Nat.succ (n + m) := by
  sorry

theorem nat_succ_add_133 (n m : Nat) : Nat.succ n + m = Nat.succ (n + m) := by
  sorry

theorem nat_succ_ne_zero_134 (n : Nat) : Not (Nat.succ n = 0) := by
  sorry

theorem nat_zero_ne_succ_135 (n : Nat) : Not (0 = Nat.succ n) := by
  sorry

theorem nat_add_comm_136 (n m : Nat) : n + m = m + n := by
  sorry

theorem nat_add_assoc_137 (a b c : Nat) : (a + b) + c = a + (b + c) := by
  sorry

theorem nat_mul_comm_138 (n m : Nat) : n * m = m * n := by
  sorry

theorem nat_mul_assoc_139 (a b c : Nat) : (a * b) * c = a * (b * c) := by
  sorry

theorem nat_left_distrib_140 (a b c : Nat) : a * (b + c) = a * b + a * c := by
  sorry

theorem nat_right_distrib_141 (a b c : Nat) : (a + b) * c = a * c + b * c := by
  sorry

theorem nat_add_left_cancel_142 (a b c : Nat) (h : a + b = a + c) : b = c := by
  sorry

theorem nat_add_right_cancel_143 (a b c : Nat) (h : b + a = c + a) : b = c := by
  sorry

theorem nat_le_refl_144 (n : Nat) : n <= n := by
  sorry

theorem nat_le_trans_145 (a b c : Nat) (hab : a <= b) (hbc : b <= c) : a <= c := by
  sorry

theorem nat_lt_trans_146 (a b c : Nat) (hab : a < b) (hbc : b < c) : a < c := by
  sorry

theorem nat_lt_of_lt_of_le_147 (a b c : Nat) (hab : a < b) (hbc : b <= c) : a < c := by
  sorry

theorem nat_le_of_lt_148 (a b : Nat) (h : a < b) : a <= b := by
  sorry

theorem nat_zero_le_149 (n : Nat) : 0 <= n := by
  sorry

theorem nat_succ_pos_150 (n : Nat) : 0 < Nat.succ n := by
  sorry

theorem nat_pred_succ_151 (n : Nat) : Nat.pred (Nat.succ n) = n := by
  sorry

theorem nat_succ_inj_152 (n m : Nat) (h : Nat.succ n = Nat.succ m) : n = m := by
  sorry

theorem nat_add_eq_zero_153 (n m : Nat) (h : n + m = 0) : n = 0 := by
  sorry

theorem nat_mul_eq_zero_154 (n m : Nat) (h : n * m = 0) : Or (n = 0) (m = 0) := by
  sorry

theorem nat_two_add_155 (n : Nat) : 2 + n = Nat.succ (Nat.succ n) := by
  sorry

theorem nat_add_two_156 (n : Nat) : n + 2 = Nat.succ (Nat.succ n) := by
  sorry

theorem nat_three_add_157 (n : Nat) : 3 + n = Nat.succ (Nat.succ (Nat.succ n)) := by
  sorry

theorem nat_add_three_158 (n : Nat) : n + 3 = Nat.succ (Nat.succ (Nat.succ n)) := by
  sorry

theorem nat_one_add_159 (n : Nat) : 1 + n = Nat.succ n := by
  sorry

theorem nat_add_one_160 (n : Nat) : n + 1 = Nat.succ n := by
  sorry

theorem bool_and_true_161 (b : Bool) : (b && true) = b := by
  sorry

theorem bool_true_and_162 (b : Bool) : (true && b) = b := by
  sorry

theorem bool_or_false_163 (b : Bool) : (b || false) = b := by
  sorry

theorem bool_false_or_164 (b : Bool) : (false || b) = b := by
  sorry

theorem bool_not_true_165 : (!true) = false := by
  sorry

theorem bool_not_false_166 : (!false) = true := by
  sorry

theorem bool_cond_true_167 (a b : Nat) : (if true then a else b) = a := by
  sorry

theorem bool_cond_false_168 (a b : Nat) : (if false then a else b) = b := by
  sorry

theorem option_some_inj_169 (n m : Nat) (h : some n = (some m : Option Nat)) : n = m := by
  sorry

theorem option_none_ne_some_170 (n : Nat) : Not ((none : Option Nat) = some n) := by
  sorry

theorem option_some_ne_none_171 (n : Nat) : Not ((some n : Option Nat) = none) := by
  sorry

theorem list_nil_append_172 (xs : List Nat) : [] ++ xs = xs := by
  sorry

theorem list_append_nil_173 (xs : List Nat) : xs ++ [] = xs := by
  sorry

theorem list_append_assoc_174 (xs ys zs : List Nat) : (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
  sorry

theorem list_length_nil_175 : ([] : List Nat).length = 0 := by
  sorry

theorem list_length_cons_176 (n : Nat) (xs : List Nat) : (n :: xs).length = Nat.succ xs.length := by
  sorry

theorem list_cons_ne_nil_177 (n : Nat) (xs : List Nat) : Not (n :: xs = []) := by
  sorry

theorem list_nil_ne_cons_178 (n : Nat) (xs : List Nat) : Not (([] : List Nat) = n :: xs) := by
  sorry

theorem list_head_cons_179 (n : Nat) (xs : List Nat) : (n :: xs).head? = some n := by
  sorry

theorem list_cons_self_180 (n : Nat) (xs : List Nat) : n :: xs = n :: xs := by
  sorry

theorem prod_fst_181 (a b : Nat) : Prod.fst (a, b) = a := by
  sorry

theorem prod_snd_182 (a b : Nat) : Prod.snd (a, b) = b := by
  sorry

theorem prod_eta_183 (p : Nat × Nat) : (p.1, p.2) = p := by
  sorry

theorem unit_eq_184 (u : Unit) : u = () := by
  sorry

theorem punit_true_185 : True := by
  sorry

theorem fun_id_nat_186 (f : Nat -> Nat) (n : Nat) : f n = f n := by
  sorry

theorem fun_congr_nat_187 (f g : Nat -> Nat) (h : f = g) (n : Nat) : f n = g n := by
  sorry

theorem fun_comp_id_left_188 (f : Nat -> Nat) (n : Nat) : (fun x => f x) n = f n := by
  sorry

theorem fun_const_189 (n m : Nat) : (fun _ : Nat => n) m = n := by
  sorry

theorem fun_apply_190 (f : Nat -> Nat) (n : Nat) : f n = f n := by
  sorry

theorem sigma_exists_191 (n : Nat) : Exists (fun m : Nat => m = n) := by
  sorry

theorem exists_true_192 : Exists (fun _ : Nat => True) := by
  sorry

theorem exists_of_eq_193 (n m : Nat) (h : n = m) : Exists (fun k : Nat => k = m) := by
  sorry

theorem exists_and_194 (p : Prop) (hp : p) : Exists (fun _ : Nat => p) := by
  sorry

theorem forall_id_195 (p : Nat -> Prop) (h : forall n, p n) (m : Nat) : p m := by
  sorry

theorem forall_const_196 (p : Prop) (hp : p) : forall _ : Nat, p := by
  sorry

theorem forall_imp_197 (p q : Nat -> Prop) (h : forall n, p n -> q n) (hp : forall n, p n) (m : Nat) : q m := by
  sorry

theorem exists_project_198 (p : Nat -> Prop) (h : Exists p) : True := by
  sorry

theorem forall_true_199 : forall _ : Nat, True := by
  sorry

theorem exists_zero_200 : Exists (fun n : Nat => n = 0) := by
  sorry

theorem eq_cast_201 (a b : Nat) (h : a = b) : a = b := by
  sorry

theorem eq_rec_self_202 (a : Nat) : a = a := by
  sorry

theorem eq_subst_prop_203 (p q : Prop) (h : p = q) (hp : p) : q := by
  sorry

theorem eq_subst_bool_204 (a b : Bool) (h : a = b) : (!a) = (!b) := by
  sorry

theorem eq_subst_option_205 (a b : Nat) (h : a = b) : some a = (some b : Option Nat) := by
  sorry

theorem eq_subst_list_206 (a b : Nat) (h : a = b) (xs : List Nat) : a :: xs = b :: xs := by
  sorry

theorem eq_subst_pair_left_207 (a b c : Nat) (h : a = b) : (a, c) = (b, c) := by
  sorry

theorem eq_subst_pair_right_208 (a b c : Nat) (h : a = b) : (c, a) = (c, b) := by
  sorry

theorem eq_subst_pred_209 (a b : Nat) (h : a = b) : Nat.pred a = Nat.pred b := by
  sorry

theorem eq_subst_decide_210 (p : Prop) [Decidable p] : decide p = decide p := by
  sorry

theorem mixed_and_eq_211 (n m : Nat) (h : n = m) : And (n = m) (m = n) := by
  sorry

theorem mixed_or_eq_212 (n m : Nat) (h : n = m) : Or (n = m) (Not (n = m)) := by
  sorry

theorem mixed_imp_eq_213 (n m : Nat) (h : n = m) : n + 0 = m := by
  sorry

theorem mixed_imp_eq_214 (n m : Nat) (h : n = m) : 0 + n = m := by
  sorry

theorem mixed_nat_prop_215 (n : Nat) (p : Prop) (hp : p) : And (n = n) p := by
  sorry

theorem mixed_nat_prop_216 (n : Nat) (p : Prop) (hp : p) : Or (n = Nat.succ n) p := by
  sorry

theorem mixed_list_nat_217 (n : Nat) (xs : List Nat) : (n :: xs).length = xs.length + 1 := by
  sorry

theorem mixed_option_nat_218 (n : Nat) : some n = (some n : Option Nat) := by
  sorry

theorem mixed_option_nat_219 : (none : Option Nat) = none := by
  sorry

theorem mixed_bool_prop_220 (p : Prop) (hp : p) : And (true = true) p := by
  sorry

theorem imp_and_221 (p q r : Prop) (hp : p) (hq : q) : r -> And p q := by
  sorry

theorem imp_or_222 (p q r : Prop) (hp : p) : r -> Or p q := by
  sorry

theorem imp_exists_223 (p : Prop) (hp : p) : True -> Exists (fun _ : Nat => p) := by
  sorry

theorem imp_forall_224 (p : Prop) (hp : p) : True -> forall _ : Nat, p := by
  sorry

theorem imp_eq_225 (n : Nat) : True -> n = n := by
  sorry

theorem hardish_and_or_226 (p q r : Prop) (h : And p (Or q r)) : Or (And p q) (And p r) := by
  sorry

theorem hardish_or_and_227 (p q r : Prop) (h : Or (And p q) (And p r)) : And p (Or q r) := by
  sorry

theorem hardish_de_morgan_228 (p q : Prop) (hp : Not p) (hq : Not q) : Not (Or p q) := by
  sorry

theorem hardish_not_and_229 (p q : Prop) (h : Not (And p q)) (hp : p) : Not q := by
  sorry

theorem hardish_or_imp_230 (p q r : Prop) (h : Or p q) (hp : p -> r) (hq : q -> r) : r := by
  sorry

theorem hardish_nat_eq_231 (a b c : Nat) (hab : a = b) (hbc : b = c) : a + 0 = c := by
  sorry

theorem hardish_nat_eq_232 (a b c : Nat) (hab : a = b) (hbc : b = c) : Nat.succ a = Nat.succ c := by
  sorry

theorem hardish_nat_le_233 (a b c d : Nat) (hab : a <= b) (hbc : b <= c) (hcd : c <= d) : a <= d := by
  sorry

theorem hardish_nat_lt_234 (a b c d : Nat) (hab : a < b) (hbc : b < c) (hcd : c < d) : a < d := by
  sorry

theorem hardish_pair_235 (a b c d : Nat) (h1 : a = c) (h2 : b = d) : (a, b) = (c, d) := by
  sorry

theorem hardish_list_236 (xs ys : List Nat) (h : xs = ys) : xs ++ [] = ys := by
  sorry

theorem hardish_list_237 (x y : Nat) (xs ys : List Nat) (hx : x = y) (hxs : xs = ys) : x :: xs = y :: ys := by
  sorry

theorem hardish_option_238 (x y : Nat) (h : x = y) : some x = (some y : Option Nat) := by
  sorry

theorem hardish_forall_239 (p q : Nat -> Prop) (h : forall n, p n -> q n) (hp : forall n, p n) : forall n, q n := by
  sorry

theorem hardish_exists_240 (p q : Nat -> Prop) (h : Exists p) (hpq : forall n, p n -> q n) : Exists q := by
  sorry

end core_eval
