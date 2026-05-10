namespace prop_smoke

theorem prop_and_left (p q : Prop) (h : And p q) : p := by
  exact h.left

end prop_smoke
