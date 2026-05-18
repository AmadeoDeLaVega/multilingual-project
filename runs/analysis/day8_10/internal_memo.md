# Day 8-10 Internal Memo

## Scope

This memo summarizes the local Day 8-10 deliverables built from the copied Nexus proof-search result directories:

- `runs/proof_search_core_eval/6848604`
- `runs/proof_search_minif2f_easy10/6849079`
- `runs/proof_search_minif2f_remaining_9h20/6850148`

CoreEval is the controlled in-project Lean 4 benchmark. The two miniF2F runs are combined below and treated as one external Lean 3 generalization check. CoreEval and miniF2F should be interpreted together rather than collapsed into a single winner.

## Main CoreEval Result

| experiment | attempted | proved | pass_rate | intersection_proved | intersection_pass_rate |
| --- | --- | --- | --- | --- | --- |
| E1 | 127 | 49 | 0.386 | 49 | 0.386 |
| E3 | 141 | 43 | 0.305 | 39 | 0.307 |
| E4 | 198 | 126 | 0.636 | 78 | 0.614 |

On CoreEval, E4 is ahead of both E1 and E3. E1 is also ahead of E3 on the theorem-name intersection attempted by all three models. This is consistent with pseudo-multilingual regularization helping on Lean-like in-distribution theorem statements.

## miniF2F Result

| experiment | attempted | proved | pass_rate | intersection_proved | intersection_pass_rate |
| --- | --- | --- | --- | --- | --- |
| E1 | 77 | 2 | 0.026 | 2 | 0.026 |
| E3 | 81 | 4 | 0.049 | 4 | 0.052 |
| E4 | 87 | 3 | 0.034 | 3 | 0.039 |

Combined miniF2F makes E1 and E4 more comparable than CoreEval does, while E3 remains competitive. This supports the concern that CoreEval is favorable to E4 and that real multilingual training may matter more on external theorem styles.

## CoreEval Search Diagnostics

| experiment | valid_tactics/state | accepted_action_rate | early_dead_end_rate | mean_tree_nodes | mean_branching | mean_time_s |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | 12.060 | 1.000 | 0.000 | 3.141 | 4.164 | 231.338 |
| E3 | 12.840 | 1.000 | 0.000 | 2.915 | 3.258 | 195.715 |
| E4 | 12.789 | 1.000 | 0.000 | 3.232 | 3.929 | 150.511 |

## miniF2F Search Diagnostics

| experiment | valid_tactics/state | accepted_action_rate | early_dead_end_rate | mean_tree_nodes | mean_branching | mean_time_s |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | 11.358 | 1.000 | 0.000 | 2.117 | 2.137 | 490.195 |
| E3 | 12.941 | 1.000 | 0.000 | 2.185 | 1.981 | 456.315 |
| E4 | 11.781 | 1.000 | 0.000 | 2.195 | 2.298 | 405.301 |

The generated-action metrics should be read as parser/action acceptance, not as guaranteed Lean compilation. Proof-tree statistics are a stronger proxy for search expansion because they are produced by the proof-search engine after interacting with Lean.

## Token-Budget Caveat

A finalized token-budget note was not present in the local artifacts used for this analysis. The plan records that E3 used a deadline-compatible multilingual split rather than the ideal final token-matched Lean+Coq mixture, and E4 still needs a more careful pseudo-Lean transformation audit. Therefore these results are useful pilot evidence, but they should not be presented as a clean causal token-matched comparison.

## Interpretation

- H1, structural transfer: not supported by CoreEval alone, but miniF2F provides suggestive evidence that real multilingual training can help external generalization.
- H2, regularization: CoreEval favors E4, supporting the idea that pseudo-multilingual variation helps on in-distribution Lean-style proof search.
- H3, search calibration: still plausible as a mechanism to inspect, especially because the miniF2F runs are timeout-heavy and differences may appear in search behavior before large pass-rate gaps emerge.
- Distribution-dependent finding: the strongest current story is not one global winner. CoreEval shows when regularization matters; miniF2F shows where real multilingual transfer may matter.

## Deliverable Files

- Tables: `runs/analysis/day8_10/tables/`
- Figures: `runs/analysis/day8_10/figures/`
- Machine-readable payload: `runs/analysis/day8_10/analysis_payload.json`
