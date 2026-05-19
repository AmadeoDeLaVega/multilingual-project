# Day 8-10 Internal Memo

## Scope

This memo summarizes the local Day 8-10 deliverables built from the copied Nexus proof-search result directories:

- `runs/proof_search_core_eval/6848604`
- `runs/proof_search_minif2f_easy10/6849079`
- `runs/proof_search_minif2f_remaining_9h20/6850148`

Easy_Lean is the controlled in-project Lean 4 benchmark. Hard_Lean combines the two miniF2F-derived runs and is treated as one external Lean 3 generalization check. Easy_Lean and Hard_Lean should be interpreted together rather than collapsed into a single winner.

## Main Easy_Lean Result

| experiment | attempted | proved | pass_rate | intersection_proved | intersection_pass_rate |
| --- | --- | --- | --- | --- | --- |
| E1 | 127 | 49 | 0.386 | 49 | 0.386 |
| E3 | 141 | 43 | 0.305 | 39 | 0.307 |
| E4 | 198 | 126 | 0.636 | 78 | 0.614 |

On Easy_Lean, E4 is ahead of both E1 and E3. E1 is also ahead of E3 on the theorem-name intersection attempted by all three models. This is consistent with pseudo-multilingual regularization helping on Lean-like in-distribution theorem statements.

## Hard_Lean Result

| experiment | attempted | proved | pass_rate | intersection_proved | intersection_pass_rate |
| --- | --- | --- | --- | --- | --- |
| E1 | 77 | 2 | 0.026 | 2 | 0.026 |
| E3 | 81 | 4 | 0.049 | 4 | 0.052 |
| E4 | 87 | 3 | 0.034 | 3 | 0.039 |

Hard_Lean makes E1 and E4 more comparable than Easy_Lean does, while E3 remains competitive. This supports the concern that Easy_Lean is favorable to E4 and that real multilingual training may matter more on external theorem styles.

### Hard_Lean Proved Theorems

The combined Hard_Lean proved theorems were:

| model | proved theorem | time_s | proof tactic |
| --- | --- | --- | --- |
| E1 | `mathd_numbertheory_342` | 122.100 | `norm_num1` |
| E1 | `mathd_algebra_176` | 57.400 | `ring` |
| E3 | `amc12b_2020_p2` | 114.800 | `ring1` |
| E3 | `mathd_numbertheory_207` | 100.700 | `norm_num` |
| E3 | `mathd_algebra_329` | 68.600 | `linarith` |
| E3 | `mathd_algebra_176` | 85.700 | `ring` |
| E4 | `mathd_numbertheory_207` | 114.600 | `ring` |
| E4 | `mathd_algebra_176` | 86.200 | `ring1` |
| E4 | `mathd_numbertheory_175` | 92.100 | `norm_num` |

Overlap:

- All three models proved `mathd_algebra_176`.
- E3 and E4 both proved `mathd_numbertheory_207`.
- E1 uniquely proved `mathd_numbertheory_342`.
- E3 uniquely proved `amc12b_2020_p2` and `mathd_algebra_329`.
- E4 uniquely proved `mathd_numbertheory_175`.

## Easy_Lean Search Diagnostics

| experiment | valid_tactics/state | accepted_action_rate | early_dead_end_rate | mean_tree_nodes | mean_branching | mean_time_s |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | 12.060 | 1.000 | 0.000 | 3.141 | 4.164 | 231.338 |
| E3 | 12.840 | 1.000 | 0.000 | 2.915 | 3.258 | 195.715 |
| E4 | 12.789 | 1.000 | 0.000 | 3.232 | 3.929 | 150.511 |

## Hard_Lean Search Diagnostics

| experiment | valid_tactics/state | accepted_action_rate | early_dead_end_rate | mean_tree_nodes | mean_branching | mean_time_s |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | 11.358 | 1.000 | 0.000 | 2.117 | 2.137 | 490.195 |
| E3 | 12.941 | 1.000 | 0.000 | 2.185 | 1.981 | 456.315 |
| E4 | 11.781 | 1.000 | 0.000 | 2.195 | 2.298 | 405.301 |

The generated-action metrics should be read as parser/action acceptance, not as guaranteed Lean compilation. Proof-tree statistics are a stronger proxy for search expansion because they are produced by the proof-search engine after interacting with Lean.

## Token-Budget Caveat

A finalized token-budget note was not present in the local artifacts used for this analysis. The plan records that E3 used a deadline-compatible multilingual split rather than the ideal final token-matched Lean+Coq mixture, and E4 still needs a more careful pseudo-Lean transformation audit. Therefore these results are useful pilot evidence, but they should not be presented as a clean causal token-matched comparison.

## Interpretation

- H1, structural transfer: not supported by Easy_Lean alone, but Hard_Lean provides suggestive evidence that real multilingual training can help external generalization.
- H2, regularization: Easy_Lean favors E4, supporting the idea that pseudo-multilingual variation helps on in-distribution Lean-style proof search.
- H3, search calibration: still plausible as a mechanism to inspect, especially because the Hard_Lean runs are timeout-heavy and differences may appear in search behavior before large pass-rate gaps emerge.
- Distribution-dependent finding: the strongest current story is not one global winner. Easy_Lean shows when regularization matters; Hard_Lean shows where real multilingual transfer may matter.

## Deliverable Files

- Tables: `runs/analysis/day8_10/tables/`
- Figures: `runs/analysis/day8_10/figures/`
- Machine-readable payload: `runs/analysis/day8_10/analysis_payload.json`
