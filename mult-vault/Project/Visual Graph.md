# Visual Graph

This note is a hub for navigating the project like a concept map in Obsidian.

```mermaid
graph TD
    A[PLAN] --> B[Project/Plan Explained]
    A --> C[Project/Visual Graph]

    B --> D[Concepts/Monolingual Training]
    B --> E[Concepts/Multilingual Training]
    B --> F[Concepts/Pseudo-multilingual Training]
    B --> G[Concepts/Regularization]
    B --> H[Concepts/Baseline]
    B --> I[Concepts/Metric]
    B --> J[Concepts/Proof Search]
    B --> K[Concepts/Search Calibration]
    B --> L[Concepts/Fine-tuning]
    B --> M[Concepts/Domain Adaptation]

    D --> N[Concepts/Model]
    E --> N
    F --> N
    N --> O[Concepts/Training]
    O --> P[Concepts/Dataset]
    P --> Q[Concepts/Token]

    I --> R[Concepts/pass@k]
    I --> S[Concepts/Compilable Tactic Rate]

    L --> T[Concepts/CategoryTheory Dataset]
    M --> T
    J --> S
    J --> K
```

## How to read this graph

- `PLAN` is the technical execution document.
- [[Project/Plan Explained]] is the plain-language explanation.
- The concept notes in [[Concepts]] define the ideas used in the plan.
- The optional adaptation branch goes through [[Concepts/Fine-tuning]] and [[Concepts/Domain Adaptation]].

## Manual navigation map

### Project layer
- [[PLAN]]
- [[Project/00 Overview]]
- [[Project/Plan Explained]]
- [[Project/Visual Graph]]

### Core experiment ideas
- [[Concepts/Baseline]]
- [[Concepts/Monolingual Training]]
- [[Concepts/Multilingual Training]]
- [[Concepts/Pseudo-multilingual Training]]
- [[Concepts/Regularization]]

### Modeling and data
- [[Concepts/Model]]
- [[Concepts/Training]]
- [[Concepts/Dataset]]
- [[Concepts/Token]]

### Evaluation
- [[Concepts/Metric]]
- [[Concepts/pass@k]]
- [[Concepts/Compilable Tactic Rate]]
- [[Concepts/Proof Search]]
- [[Concepts/Search Calibration]]

### Optional adaptation branch
- [[Concepts/Fine-tuning]]
- [[Concepts/Domain Adaptation]]
- [[Concepts/CategoryTheory Dataset]]
