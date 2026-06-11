# AIR Blackbox Compliance Scan - GitHub Action

Scan your Python AI projects for EU AI Act compliance in CI/CD. One line in your workflow, 51+ checks across 6 articles.

```yaml
- uses: airblackbox/scan-action@v1
```

## Quick Start

Add this to `.github/workflows/compliance.yml`:

```yaml
name: AI Compliance Scan
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: airblackbox/scan-action@v1
        with:
          threshold: 60
          fail-on: high
```

That's it. Every push gets scanned. PRs get a compliance comment. Builds fail if the score drops below 60 or any high-severity finding is detected.

## What It Checks

The scanner maps to EU AI Act technical requirements:

| Article | Requirement | Example Checks |
|---------|-------------|----------------|
| Art. 9  | Risk Management | Risk assessment docs, mitigation strategies |
| Art. 10 | Data Governance | Training data documentation, bias checks |
| Art. 11 | Technical Documentation | Model cards, system architecture docs |
| Art. 12 | Record-Keeping | Audit logging, tamper-evident trails |
| Art. 14 | Human Oversight | Human-in-the-loop controls, override mechanisms |
| Art. 15 | Robustness | Error handling, input validation, fallback behavior |

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `path` | Path to scan (relative to repo root) | `.` |
| `threshold` | Minimum compliance score (0-100). Build fails below this. | `0` (never fail on score) |
| `fail-on` | Fail on findings of this severity or higher: `high`, `medium`, `low`, or `none` | `none` |
| `frameworks` | Comma-separated frameworks: `eu-ai-act`, `iso-42001`, `nist-ai-rmf`, `colorado-sb-205`, or `all` | `eu-ai-act` |
| `version` | Version of `air-compliance-checker` to install | `latest` |
| `comment` | Post scan results as a PR comment (`true`/`false`). Needs `GITHUB_TOKEN`. | `true` |
| `badge` | Generate a compliance badge SVG in the repo (`true`/`false`) | `false` |
| `json-output` | Path to write raw JSON scan results (empty = skip) | `` |

## Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `score` | Overall compliance score (0-100) | `73` |
| `total-findings` | Total number of compliance findings | `12` |
| `high-findings` | Number of high-severity findings | `2` |
| `medium-findings` | Number of medium-severity findings | `5` |
| `low-findings` | Number of low-severity findings | `5` |
| `passed` | Whether the scan passed all thresholds | `true` |

## Examples

### Basic: Scan on Every PR

```yaml
name: Compliance
on: pull_request

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: airblackbox/scan-action@v1
```

### Strict: Fail on Any High-Severity Finding

```yaml
- uses: airblackbox/scan-action@v1
  with:
    threshold: 70
    fail-on: high
```

### Multi-Framework: EU AI Act + ISO 42001

```yaml
- uses: airblackbox/scan-action@v1
  with:
    frameworks: eu-ai-act,iso-42001
    threshold: 50
```

### Scan a Specific Directory

```yaml
- uses: airblackbox/scan-action@v1
  with:
    path: src/ai_pipeline
```

### Save JSON Results as an Artifact

```yaml
- uses: airblackbox/scan-action@v1
  id: scan
  with:
    json-output: compliance-results.json

- uses: actions/upload-artifact@v4
  if: always()
  with:
    name: compliance-report
    path: compliance-results.json
```

### Use Outputs in Later Steps

```yaml
- uses: airblackbox/scan-action@v1
  id: scan

- run: echo "Compliance score is ${{ steps.scan.outputs.score }}/100"

- if: steps.scan.outputs.high-findings != '0'
  run: echo "::warning::${{ steps.scan.outputs.high-findings }} high-severity findings need attention"
```

### Generate a Compliance Badge

```yaml
- uses: airblackbox/scan-action@v1
  with:
    badge: true

# Badge is written to .air-compliance-badge.svg
# Commit it back or upload as an artifact
```

### Pin a Specific Scanner Version

```yaml
- uses: airblackbox/scan-action@v1
  with:
    version: '0.5.2'
```

## PR Comments

When `comment: true` (the default) and the action runs on a pull request, it posts a comment like this:

> **AIR Blackbox Compliance Scan: 73/100**
>
> **12 findings** (2 high, 5 medium, 5 low)
>
> | Article | Name | Score | Checks | Status |
> |---------|------|-------|--------|--------|
> | Art. 9  | Risk Management | 80% | 4/5 | :white_check_mark: |
> | Art. 12 | Record-Keeping | 45% | 3/7 | :x: |
> | ... | | | | |

The comment requires `GITHUB_TOKEN` which is automatically available in GitHub Actions workflows.

## Badge

Set `badge: true` to generate an SVG badge at `.air-compliance-badge.svg`:

![AIR Compliance 73%](https://img.shields.io/badge/AIR_Compliance-73%25-yellow)

Add it to your README:

```markdown
![AIR Compliance](/.air-compliance-badge.svg)
```

## Requirements

- Python 3.9+ (the action sets up Python 3.11 automatically)
- A Python AI project with code to scan

No API keys required. The scanner runs entirely locally.

## EU AI Act Timeline

- **Aug 2, 2025**: GPAI model obligations apply
- **Aug 2, 2026**: High-risk AI system rules take effect
- **Penalties**: Up to EUR 35M or 7% of global turnover

Start scanning now. Fix findings before the deadline.

## Links

- [AIR Blackbox](https://airblackbox.ai) - Full compliance platform
- [Fix Findings Guide](https://airblackbox.ai/guides) - How to resolve compliance gaps
- [CLI Scanner](https://pypi.org/project/air-compliance-checker/) - The scanner this action uses
- [Compliance Mapping](https://airblackbox.ai/compliance-mapping) - EU AI Act to ISO 42001 to NIST AI RMF

## License

MIT
