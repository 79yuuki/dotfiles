# Path split note

In this environment, `skill_manage` may update `/Users/angoya-claw/.hermes/skills/research/blogwatcher` while `skill_view('blogwatcher')` resolves `/Users/angoya-claw/.openclaw/workspace/skills/blogwatcher`. For active-session behavior, verify `skill_view.skill_dir` and patch that directory directly when the paths diverge.
