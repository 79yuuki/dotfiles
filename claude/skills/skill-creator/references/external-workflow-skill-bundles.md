# External workflow skill bundle migration notes

Use this when turning an external development-methodology bundle (for example, Superpowers-style Claude/Codex skills) into a portable user dotfiles setup.

## Learned workflow

1. Work locally first in the dotfiles clone, on a branch.
2. Prefer generic/class-level skill names. Do not add project/user prefixes to skill folder names unless the skill is truly project-specific.
3. For Claude Code, prefer the official marketplace/plugin as the source of truth when available. Avoid enabling duplicate copies from multiple marketplaces because duplicated bootstrap/routing skills can compete.
4. For Codex, summarize the same class-level workflows in `codex/AGENTS.md` when Codex skill/plugin support is absent or not portable.
5. Scan each copied skill directory individually with `skill-security-scan.sh`; do not scan only the parent bundle directory.
6. If a copied skill gets CRITICAL/HIGH from the scanner and the scanner does not provide actionable details, do not ship it locally. Either omit it, rely on official plugin delivery, or encode a concise safe summary in AGENTS.md.
7. Verify no old prefix remains with a repository grep before committing.
8. Treat `git push` and PR creation as outbound privileged actions requiring scoped approval.

## Commands

```bash
# per-skill scan loop
for d in claude/skills/*; do
  [ -f "$d/SKILL.md" ] || continue
  /Users/angoya-claw/.agent-runtime/workspace/scripts/skill-security-scan.sh "$PWD/$d" > "/tmp/scan-$(basename "$d").log"
done

grep -RHiE "Max Severity: (CRITICAL|HIGH)|suspicious pattern\\(s\\) detected|Error loading skill" /tmp/scan-*.log || true

grep -RIn "muser\\|Muser\\|superpowers:" README.md codex claude 2>/dev/null || true
```

## Pitfalls

- The scanner script exits 0 even when Cisco reports HIGH/CRITICAL; parse the log text.
- Scanning `claude/skills/` as a parent produces `SKILL.md not found`; it is not a valid pass.
- Scanner false positives can come from examples or helper scripts, but CRITICAL/HIGH still require removal, omission, or safe rewrite before committing.
