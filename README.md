# AIR Blackbox — EU AI Act Compliance Action

Scan your Python AI code for EU AI Act technical compliance on every push. Zero config. Two-tier scoring separates what you can fix now (static) from what needs infrastructure (runtime).

**18+ checks across 6 EU AI Act articles:**

| Article | What it checks | Example patterns |
|---------|---------------|------------------|
| Article 9 — Risk Management | Error handling, fallbacks, retry logic | `try/except`, `with_fallbacks()`, `tenacity` |
| Article 10 — Data Governance | Input validation, PII handling | `Pydantic`, `presidio`, `sanitize` |
| Article 11 — Technical Docs | Docstrings, type hints, model cards | `"""docstring"""`, `-> str`, `README.md` |
| Article 12 — Record-Keeping | Logging, tracing, audit trails | `structlog`, `OpenTelemetry`, `audit_log` |
| Article 14 — Human Oversight | HITL gates, rate limits, identity binding | `human_approval`, `max_tokens`, `user_id` |
| Article 15 — Accuracy & Security | Injection defense, output validation | `guardrail`, `OutputParser`, `retry` |

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

Every PR now shows a compliance score in the GitHub Actions step summary.

## With threshold enforcement

```yaml
      - uses: airblackbox/compliance-action@v1
        with:
          fail-on-findings: 'true'
          min-score: 60
```

PRs below 60% compliance will fail. Set your own bar.

## Using outputs in downstream steps

```yaml
      - uses: airblackbox/compliance-action@v1
        id: compliance

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `## EU AI Act Compliance\nScore: **${{ steps.compliance.outputs.score }}** (${{ steps.compliance.outputs.score-percent }}%)\nStatic: ${{ steps.compliance.outputs.static-passing }}/${{ steps.compliance.outputs.static-total }} | Runtime: ${{ steps.compliance.outputs.runtime-passing }}/${{ steps.compliance.outputs.runtime-total }}`
            })
```

## Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `path` | `.` | Directory to scan |
| `fail-on-findings` | `false` | Block PRs on compliance gaps |
| `max-failures` | `0` | Maximum allowed failures (when fail-on-findings is true) |
| `min-score` | `0` | Minimum passing score percentage (0-100) |
| `version` | latest | Pin a specific AIR Blackbox version |

## Outputs

| Output | Description |
|--------|-------------|
| `passing` | Number of passing checks |
| `warnings` | Number of warnings |
| `failing` | Number of failing checks |
| `total` | Total checks run |
| `score` | Score as `passing/total` |
| `score-percent` | Score as percentage (0-100) |
| `static-passing` | Static checks passing |
| `static-total` | Total static checks |
| `runtime-passing` | Runtime checks passing |
| `runtime-total` | Total runtime checks |
| `frameworks` | Detected frameworks (comma-separated) |

## Two-tier scoring

Not all compliance checks are created equal. AIR Blackbox separates:

- **Static checks** — code patterns, documentation, config. Fix these by changing your code.
- **Runtime checks** — require a gateway or trust layer. These need infrastructure.

The step summary shows both tiers so you know exactly what to fix now vs. what to plan for.

## What this is (and isn't)

This checks **technical requirements** — code patterns that map to EU AI Act articles. It's a linter for AI governance, not a legal compliance tool. Think ESLint for regulatory readiness.

**Deadline: August 2, 2026** — High-risk AI system rules take effect. Fines up to 35M EUR or 7% of global turnover.

## Links

- [AIR Blackbox CLI](https://pypi.org/project/air-blackbox/) — the scanner on PyPI
- [AIR Blackbox MCP](https://pypi.org/project/air-blackbox-mcp/) — MCP server for Claude Desktop/Cursor
- [airblackbox.ai](https://airblackbox.ai) — project homepage
- [GitHub org](https://github.com/airblackbox)

---

MIT License · Built by [AIR Blackbox](https://github.com/airblackbox)
