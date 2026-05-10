namespace debug_smoke

theorem prop_id
  (p : Prop)
  (hp : p)
  : p := by
  exact hp

theorem prop_and_intro
  (p q : Prop)
  (hp : p)
  (hq : q)
  : And p q := by
  exact And.intro hp hq

end debug_smoke
