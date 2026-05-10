namespace smoke

theorem smoke_true : True := by
  sorry

theorem smoke_id_prop (p : Prop) (hp : p) : p := by
  sorry

theorem smoke_and_intro (p q : Prop) (hp : p) (hq : q) : And p q := by
  sorry

theorem smoke_and_left (p q : Prop) (h : And p q) : p := by
  sorry

theorem smoke_and_right (p q : Prop) (h : And p q) : q := by
  sorry

end smoke
