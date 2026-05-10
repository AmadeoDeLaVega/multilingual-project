namespace prop_smoke

theorem prop_and_intro (p q : Prop) (hp : p) (hq : q) : And p q := by
  exact And.intro hp hq

end prop_smoke
