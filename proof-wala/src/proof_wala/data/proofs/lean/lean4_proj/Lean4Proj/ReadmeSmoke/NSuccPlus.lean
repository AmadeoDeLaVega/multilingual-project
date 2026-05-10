namespace readme_smoke

theorem n_succ_plus (n m : Nat) : Nat.succ n + m = Nat.succ (n + m) := by
  exact Nat.succ_add n m

end readme_smoke
