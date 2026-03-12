# AIR Blackbox — EU AI Act Compliance Action

Scan your Python AI code for EU AI Act technical compliance on every push. Zero config. 10 seconds.

**6 checks mapped to the actual regulation:**

| Check | EU AI Act Article | What it verifies |
|-------|------------------|-----------------|
| Risk Management | Article 9 | Risk assessment patterns in your AI pipeline |
| Data Governance | Article 10 | Data validation, bias checks, lineage tracking |
| Technical Docs | Article 11 | Docstrings, model cards, architecture docs |
| Record-Keeping | Article 12 | Audit logging, trace IDs, decision records |
| Human Oversight | Article 14 | Approval gates, human-in-the-loop patterns |
| Robustness | Article 15 | Error handling, fallbacks, input validation |

## Quick start
```yaml
# .github/workflows/compliance.yml
name: EU AI Act Compliance
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: airblackbox/compliance-action@v1
```

That's it. Every PR now shows a compliance score.

## With threshold enforcement
```yaml
      - uses: airblackbox/compliance-action@v1
        with:
          fail-on-findings: 'true'
          min-score: 60
```

PRs below score 60 will fail. Set your own bar.

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `path` | `.` | Directory to scan |
| `fail-on-findings` | `false` | Block PRs on compliance gaps |
| `output-format` | `text` | `text`, `json`, or `sarif` |
| `min-score` | `0` | Minimum passing score (0-100) |

## Outputs

| Output | Description |
|--------|-------------|
| `score` | Compliance score (0-100) |
| `checks-passed` | Checks passed out of 6 |
| `report-path` | Path to full report |

## SARIF integration

Set `output-format: sarif` to get results in GitHub's Security tab:
```yaml
      - uses: airblackbox/compliance-action@v1
        with:
          output-format: sarif
      - uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: ${{ steps.scan.outputs.report_path }}
```

## What this is (and isn't)

This checks **technical requirements** — code patterns that map to EU AI Act articles. It's a linter for AI governance, not a legal compliance tool. Think ESLint for regulatory readiness.

**Deadline: August 2, 2026** — High-risk AI system rules take effect. Fines up to €35M or 7% of global turnover.

## Links

- [GitHub org](https://github.com/airblackbox)
- [Interactive demo](https://airblackbox.ai/demo)
- [Framework trust layers](https://github.com/airblackbox) (LangChain, CrewAI, AutoGen, OpenAI, Anthropic, RAG)
- [PyPI](https://pypi.org/project/air-blackbox/)

---

Apache 2.0 · Built by [AIR Blackbox](https://github.com/airblackbox)
