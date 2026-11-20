# Third-party notices

`dotfiles/claude/skills` のうち以下の skill は [obra/superpowers](https://github.com/obra/superpowers) からの取り込みとローカル改変を含む。最終マージ: v6.4.2 (2026-10-07)。

- dispatching-parallel-agents
- executing-plans
- finishing-a-development-branch
- receiving-code-review
- requesting-code-review
- subagent-driven-development
- systematic-debugging
- test-driven-development
- using-git-worktrees
- using-superpowers
- verification-before-completion
- writing-plans

Upstream: https://github.com/obra/superpowers

## obra/superpowers LICENSE

```text
MIT License

Copyright (c) 2025 Jesse Vincent

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## cursor/plugins pstack

以下の skill は [cursor/plugins の pstack](https://github.com/cursor/plugins/tree/main/pstack) からの取り込みとローカル改変を含む。取得コミット: 246bc508c139 (2026-11-10)。

- blast-radius
- create-verification-skill（references/feature-map-example を含む）
- maintain-verification-skill
- formal-methods の `references/project-verify-skill.md`（`create-formal-verification-skill` と `maintain-formal-verification-skill` を日本語に要約して 1 ファイルにまとめた。取得コミット: fbb86c09bbb4 (2026-11-19)。`/statechart` への参照は外した）

ローカル改変: Cursor のパス `.cursor/skills/` を `.claude/skills/` に変更。blast-radius は pstack の他 skill（how / why / arena / unslop）への参照を外し、複数モデルでの確認を codex skill に置き換えた。blast-radius と create-verification-skill は `disable-model-invocation` を外し、description に日本語の起動語を足した。

### cursor/plugins pstack LICENSE

```text
MIT License

Copyright (c) 2026 Lauren Tan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## GoogleChrome/modern-web-guidance

`claude/skills/modern-web-guidance/`（Apache-2.0）は `npx modern-web-guidance@latest install` で入れる。中身はこのリポジトリに含めず `.gitignore` で除外している。導入手順と確認事項は `claude/plugins/manifest.json` の `externalSkills`。
