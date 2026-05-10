namespace readme_smoke

theorem n_plus_succ (n m : Nat) : n + Nat.succ m = Nat.succ (n + m) := by
  exact Nat.add_succ n m

end readme_smoke
