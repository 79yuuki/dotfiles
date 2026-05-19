---
name: smart-contract-audit
description: >-
  Audit Solidity smart contracts for loss-of-funds vulnerabilities, access-control bugs, economic attacks, upgradeability risks, and integration hazards. Use for authorized smart-contract security reviews before deployment or merge.
---

# Smart Contract Audit

Audit Solidity smart contracts for high-severity (loss-of-funds) vulnerabilities using the EVMbench detect methodology.

## Workflow

1. **Identify target**: Get the path to the Solidity source directory (or single file).
2. **Install tools** (if needed): Ensure `slither` is available. Run `scripts/setup_tools.sh` if not installed.
3. **Run static analysis**: Execute `scripts/run_slither.sh <target_dir>` to get initial findings.
4. **Deep manual audit**: Read all in-scope Solidity files. Focus on:
   - Reentrancy (cross-function, read-only, cross-contract)
   - Access control (missing modifiers, privilege escalation)
   - Oracle manipulation (price feeds, TWAP)
   - Integer overflow/underflow (unchecked blocks)
   - Flash loan attack vectors
   - Logic errors in state transitions
   - Token handling (approval race, double-spend, fee-on-transfer)
   - Upgradability issues (storage collisions, uninitialized proxies)
5. **Generate report**: Write `submission/audit.md` in the EVMbench JSON format (see references/report-format.md).
6. **Validate**: Run `scripts/validate_report.py submission/audit.md` to ensure JSON is parseable.

## Scope Rules

- **In scope**: Solidity source files, library dependencies used in business logic
- **Out of scope**: Test files, deployment scripts, configuration, unless user explicitly requests
- **Trusted roles**: Assume owner/admin/governance are trusted. Do NOT report privilege abuse by trusted roles.
- **Severity**: Only report HIGH severity (loss-of-funds). Skip medium/low/informational.

## Output

Final report goes to `submission/audit.md` as a JSON code block. See `references/report-format.md` for the exact schema.

## Tools

- **Slither**: Static analysis (setup via `scripts/setup_tools.sh`)
- **Manual review**: Deep code reading for logic bugs slither misses

## References

- `references/report-format.md` — Output JSON schema and examples
- `references/vulnerability-patterns.md` — Common vulnerability patterns checklist
