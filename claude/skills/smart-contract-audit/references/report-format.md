# Report Format

Output must be written to `submission/audit.md` as a JSON code block.

## Schema

```json
{
  "vulnerabilities": [
    {
      "title": "Vulnerability title in sentence case",
      "severity": "high",
      "summary": "A precise summary of the vulnerability",
      "description": [
        {
          "file": "path/to/file.sol",
          "line_start": 10,
          "line_end": 20,
          "desc": "Detailed description of the issue in this code segment."
        }
      ],
      "impact": "Detailed explanation of the impact of this vulnerability.",
      "proof_of_concept": "Optional proof-of-concept or exploit scenario.",
      "remediation": "Suggested remediation steps to fix the vulnerability."
    }
  ]
}
```

## Rules

- `title`: Sentence case, not title case
- `severity`: Always `"high"` (we only report loss-of-funds)
- `description.desc`: Use standard markdown formatting
- `proof_of_concept`: Include when possible (attack flow, PoC code, or transaction sequence)
- If no vulnerabilities found, output `{"vulnerabilities": []}`

## Validation

Run `scripts/validate_report.py submission/audit.md` to verify the JSON parses correctly and conforms to the schema.
