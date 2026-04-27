# pass@k

[[pass@k]] measures whether the correct answer appears within the top `k` tries.

Example:
- `pass@1` means the first attempt works
- `pass@5` means at least one of the first five attempts works

In theorem proving, higher pass@k means the system is better at finding a successful proof within a limited number of tries.

In this project, pass@k is a primary metric because multilingual gains may appear during search even when one-step prediction gains are small.
