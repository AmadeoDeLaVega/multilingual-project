# Search Calibration

[[Search Calibration]] means the model ranks its suggestions in a way that helps [[Proof Search]] work better.

A model may not always know the exact best next step, but it can still be useful if it places valid tactics near the top.

In the updated plan, this is important because multilingual gains may show up more clearly in search behavior than in next-step exact prediction.

That is why the pilot emphasizes metrics such as [[pass@k]] and [[Compilable Tactic Rate]] in addition to next-tactic accuracy.

Example:
- if a good tactic is ranked 2nd instead of 20th, search is much more likely to find it quickly
