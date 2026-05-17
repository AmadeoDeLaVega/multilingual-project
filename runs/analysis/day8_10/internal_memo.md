# Day 8-10 Internal Memo

## Scope

This memo summarizes the local Day 8-10 deliverables built from the copied Nexus proof-search result directories:

- `runs/proof_search_core_eval/6848604`
- `runs/proof_search_minif2f_easy10/6849079`

CoreEval is the primary benchmark for the pilot. miniF2F easy-10 is secondary because it is Lean 3 and much smaller.

## Main CoreEval Result

| experiment | attempted | proved | pass_rate | intersection_proved | intersection_pass_rate |
| --- | --- | --- | --- | --- | --- |
| E1 | 127 | 49 | 0.386 | 49 | 0.386 |
| E3 | 141 | 43 | 0.305 | 39 | 0.307 |
| E4 | 198 | 126 | 0.636 | 78 | 0.614 |

On CoreEval, E4 is ahead of both E1 and E3. E1 is also ahead of E3 on the theorem-name intersection attempted by all three models.

## miniF2F Easy-10 Result

| experiment | attempted | proved | pass_rate |
| --- | --- | --- | --- |
| E1 | 10 | 1 | 0.100 |
| E3 | 10 | 2 | 0.200 |
| E4 | 10 | 1 | 0.100 |

miniF2F easy-10 gives E3 a small edge, but the sample is only 10 theorems and should not override the CoreEval result.

## Search Diagnostics

| experiment | valid_tactics/state | accepted_action_rate | early_dead_end_rate | mean_tree_nodes | mean_branching | mean_time_s |
| --- | --- | --- | --- | --- | --- | --- |
| E1 | 12.060 | 1.000 | 0.000 | 3.141 | 4.164 | 231.338 |
| E3 | 12.840 | 1.000 | 0.000 | 2.915 | 3.258 | 195.715 |
| E4 | 12.789 | 1.000 | 0.000 | 3.232 | 3.929 | 150.511 |

The generated-action metrics should be read as parser/action acceptance, not as guaranteed Lean compilation. Proof-tree statistics are a stronger proxy for search expansion because they are produced by the proof-search engine after interacting with Lean.

## Token-Budget Caveat

A finalized token-budget note was not present in the local artifacts used for this analysis. The plan records that E3 used a deadline-compatible multilingual split rather than the ideal final token-matched Lean+Coq mixture, and E4 still needs a more careful pseudo-Lean transformation audit. Therefore these results are useful pilot evidence, but they should not be presented as a clean causal token-matched comparison.

## Interpretation

- H1, structural transfer: not supported by CoreEval, because E3 does not beat E1 or E4 there.
- H2, regularization: CoreEval favors E4, but E4 data quality remains a caveat, so this is suggestive rather than conclusive.
- H3, search calibration: still plausible as a mechanism to inspect, but the current primary result is dominated by E4's higher proof-search pass rate rather than an E3 search advantage.

## Deliverable Files

- Tables: `runs/analysis/day8_10/tables/`
- Figures: `runs/analysis/day8_10/figures/`
- Machine-readable payload: `runs/analysis/day8_10/analysis_payload.json`
