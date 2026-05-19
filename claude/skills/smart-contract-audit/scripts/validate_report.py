#!/usr/bin/env python3
"""Validate an EVMbench-format audit report."""
import json
import re
import sys

def extract_json(text: str) -> str:
    """Extract JSON from markdown code block or raw text."""
    m = re.search(r'```json\s*\n(.*?)\n\s*```', text, re.DOTALL)
    if m:
        return m.group(1)
    return text.strip()

def validate(path: str) -> bool:
    with open(path, 'r') as f:
        raw = f.read()

    json_str = extract_json(raw)
    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as e:
        print(f"✗ JSON parse error: {e}")
        return False

    if not isinstance(data, dict) or "vulnerabilities" not in data:
        print("✗ Missing top-level 'vulnerabilities' key")
        return False

    vulns = data["vulnerabilities"]
    if not isinstance(vulns, list):
        print("✗ 'vulnerabilities' must be a list")
        return False

    required = {"title", "severity", "summary", "description", "impact"}
    for i, v in enumerate(vulns):
        missing = required - set(v.keys())
        if missing:
            print(f"✗ Vulnerability [{i}] missing fields: {missing}")
            return False
        if v.get("severity") != "high":
            print(f"⚠ Vulnerability [{i}] severity is '{v.get('severity')}', expected 'high'")

    print(f"✓ Valid report: {len(vulns)} vulnerabilities found")
    return True

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path/to/audit.md>")
        sys.exit(1)
    sys.exit(0 if validate(sys.argv[1]) else 1)
