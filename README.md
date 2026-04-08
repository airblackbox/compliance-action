# AIR Blackbox Compliance Scanner Action

Automatically scan your Python AI projects for EU AI Act compliance in CI/CD. **22 checks across 6 articles.** No API key required.

[![EU AI Act Compliance](https://img.shields.io/badge/EU%20AI%20Act-Compliance%20Ready-brightgreen?style=for-the-badge)](https://airblackbox.ai)

## Quick Start

Add this to your GitHub Actions workflow:

```yaml
- uses: airblackbox/compliance-action@v1
  with:
    path: '.'
    strict: false
    badge: true
    format: 'summary'
```

That's it. The action will:
1. Scan your Python code for EU AI Act compliance issues
2. Generate a compliance report in the GitHub Actions step summary
3. Create a badge URL for your README
4. Set outputs you can use in downstream steps

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `path` | Directory to scan (usually `.` for root) | No | `.` |
| `strict` | Fail the workflow if any checks fail | No | `false` |
| `badge` | Generate a compliance badge URL | No | `true` |
| `format` | Output format: `summary`, `json`, or `verbose` | No | `summary` |

## Outputs

After running the action, access results via `${{ steps.scan.outputs.* }}`:

| Output | Description | Example |
|--------|-------------|---------|
| `score` | Compliance percentage (0-100) | `85.5` |
| `status` | Overall status: `pass`, `warn`, or `fail` | `pass` |
| `badge_url` | Shields.io badge URL for README | `https://img.shields.io/badge/...` |
| `total_checks` | Total checks executed | `22` |
| `passed` | Number of passed checks | `19` |
| `warned` | Number of warned checks | `2` |
| `failed` | Number of failed checks | `1` |

## What Gets Checked

The action scans across **6 EU AI Act articles**:

- **Article 9:** Risk Management (error handling, fallbacks, monitoring)
- **Article 10:** Data Governance (input validation, PII handling)
- **Article 11:** Technical Documentation (docstrings, type hints)
- **Article 12:** Record-Keeping (logging, tracing, audit trails)
- **Article 14:** Human Oversight (rate limits, approval workflows)
- **Article 15:** Accuracy & Security (injection defense, output validation)

Detects frameworks: **LangChain, CrewAI, AutoGen, OpenAI, Haystack, LlamaIndex**

## Usage Examples

### Basic Workflow

```yaml
name: EU AI Act Compliance Check
on: [push, pull_request]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: airblackbox/compliance-action@v1
        with:
          path: '.'
```

### Strict Mode (Block Merge)

Fail the workflow if any compliance check fails:

```yaml
- uses: airblackbox/compliance-action@v1
  with:
    path: '.'
    strict: true
```

### With Badge in README

Use the badge output to display your compliance status:

```yaml
- uses: airblackbox/compliance-action@v1
  id: compliance
  with:
    path: '.'
    badge: true

- name: Update README with badge
  run: |
    sed -i "s|!\[.*Compliance.*\].*|![${{ steps.compliance.outputs.status }}](${{ steps.compliance.outputs.badge_url }})|" README.md
    git config user.name "GitHub Actions"
    git config user.email "actions@github.com"
    git add README.md
    git commit -m "Update compliance badge" || true
    git push
```

### Monorepo with Custom Path

Scan a specific subdirectory:

```yaml
- uses: airblackbox/compliance-action@v1
  with:
    path: 'src/agents'
```

### JSON Output for Custom Processing

Get structured JSON for downstream tools:

```yaml
- uses: airblackbox/compliance-action@v1
  id: scan
  with:
    path: '.'
    format: 'json'

- name: Post to compliance dashboard
  run: |
    curl -X POST https://compliance-tracker.internal/api/scans \
      -H "Content-Type: application/json" \
      -d '{
        "repo": "${{ github.repository }}",
        "score": ${{ steps.scan.outputs.score }},
        "status": "${{ steps.scan.outputs.status }}",
        "passed": ${{ steps.scan.outputs.passed }},
        "failed": ${{ steps.scan.outputs.failed }}
      }'
```

### Verbose Mode for Detailed Debugging

```yaml
- uses: airblackbox/compliance-action@v1
  with:
    path: '.'
    format: 'verbose'
```

Outputs full article-by-article breakdown with all check details.

## Badge Examples

The action generates compliance badges automatically. Paste into your README:

```markdown
![EU AI Act Compliance](https://img.shields.io/badge/EU%20AI%20Act-92%25%20compliant-brightgreen?style=for-the-badge)
```

Badges are color-coded by score:
- 🟢 **90-100%**: Brightgreen — Ready for EU market
- 🟡 **70-89%**: Yellow — Address warnings soon
- 🟠 **50-69%**: Orange — Significant gaps remain
- 🔴 **0-49%**: Red — Major compliance work needed

## Understanding Results

### Step Summary Report

The action automatically posts a compliance report to your GitHub Actions run:

```
## 🛡️ EU AI Act Compliance Report

**Score: 85%** | **Status: PASS** | **Frameworks: LangChain, OpenAI**

| Metric | Count |
|--------|-------|
| ✅ Passed | 19 |
| ⚠️ Warned | 2 |
| ❌ Failed | 1 |
| 📊 Total | 22 |

### Article Breakdown

| Article | Title | Status | Details |
|---------|-------|--------|---------|
| ✅ Art 9 | Risk Management | PASS | ✅ Error handling present<br>✅ Fallback logic detected |
| ⚠️ Art 10 | Data Governance | WARN | ✅ Input validation found<br>⚠️ No PII encryption |
| ✅ Art 11 | Documentation | PASS | ✅ Docstrings present<br>✅ Type hints detected |
```

### Interpreting Your Score

- **Pass**: All critical checks passed. Ready for EU compliance.
- **Warn**: Some checks passed but gaps exist. Address within 2 sprints.
- **Fail**: Major compliance gaps. Requires immediate attention.

## No-Code Alternative

For teams without CI/CD set up yet, use the web scanner:

**[AIR Blackbox Web Scanner](https://airblackbox.ai/scan)**

Upload your repo or connect GitHub. Get the same 22 checks in seconds.

## What's Not Checked

This action focuses on **code-level compliance** per Articles 9-15. It does NOT cover:

- Article 5-8 (high-risk system classification, risk assessment procedures)
- Organizational policies (training, governance, incident response)
- Third-party audit requirements
- Regulatory documentation (technical file, EU database registration)

For full compliance, combine this action with:
- Manual risk assessment (Articles 5-8)
- Legal review of your AI system classification
- Audit trail documentation (preserved outside code)

## Performance

- **Runtime**: ~3-8 seconds (includes pip install)
- **No external dependencies**: Runs entirely on GitHub runners
- **No API calls**: Works offline or in air-gapped environments
- **Safe to run on every push**: Minimal compute footprint

## Troubleshooting

### Action fails with "air-compliance not found"

The pip install may have failed silently. Check your runner:

```yaml
- run: pip install air-compliance --verbose
```

### Badge URL doesn't work

Shields.io occasionally has downtime. The action uses the dynamic badge API which auto-refreshes. If stuck on old score, force a rebuild.

### JSON output is empty

Ensure your project has at least one Python file (`.py`). The scanner needs code to analyze.

### Strict mode blocking valid code

You may need to suppress specific checks. Create a `.airblackbox.yaml` in your repo:

```yaml
suppress:
  - "Article 14: Rate limiting not detected"
```

## Integration Examples

### GitLab CI

Use GitHub Actions in GitLab via bridge workflow:

```yaml
check_compliance:
  image: ubuntu:latest
  script:
    - apt-get update && apt-get install -y python3 python3-pip
    - pip install air-compliance
    - air-compliance . --json > compliance.json
    - cat compliance.json
```

### Jenkins

Integrate via shell step:

```groovy
stage('Compliance Check') {
    steps {
        sh '''
            pip install air-compliance
            air-compliance . --json > compliance.json
        '''
        archiveArtifacts artifacts: 'compliance.json'
    }
}
```

### Local Pre-Commit Hook

Test locally before pushing:

```bash
#!/bin/bash
pip install air-compliance
air-compliance . --strict
```

Save as `.git/hooks/pre-commit`, then `chmod +x .git/hooks/pre-commit`.

## Contributing

Found a bug or want to suggest a check? Open an issue on the [AIR Blackbox GitHub](https://github.com/airblackbox/compliance-action).

## License

Apache License 2.0. See [LICENSE](LICENSE).

## Support

- **Documentation**: [airblackbox.ai/docs](https://airblackbox.ai/docs)
- **Issues**: [github.com/airblackbox/compliance-action/issues](https://github.com/airblackbox/compliance-action/issues)
- **Community**: [airblackbox.ai/community](https://airblackbox.ai/community)

---

**Developed by AIR Blackbox** — Making EU AI Act compliance automatic for every AI team.

Last updated: 2026-04-07 | EU AI Act enforcement: August 2, 2026
