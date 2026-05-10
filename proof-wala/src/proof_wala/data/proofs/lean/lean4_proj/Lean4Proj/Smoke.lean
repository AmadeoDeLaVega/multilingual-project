namespace smoke

theorem smoke_true : True := by
  exact True.intro

theorem smoke_id_prop (p : Prop) (hp : p) : p := by
  exact hp

theorem smoke_and_intro (p q : Prop) (hp : p) (hq : q) : And p q := by
  exact And.intro hp hq

theorem smoke_and_left (p q : Prop) (h : And p q) : p := by
  exact h.left

theorem smoke_and_right (p q : Prop) (h : And p q) : q := by
  exact h.right

end smoke
