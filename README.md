# Codex Token Optimizer

A lightweight Codex skill for reducing token waste during software development without sacrificing correctness.

It promotes targeted file reading, bounded terminal output, focused tool usage, context hygiene, and reliable verification for long or noisy coding tasks.

## Installation

Copy this directory into your user-level Codex skills directory:

```text
~/.agents/skills/codex-token-optimizer/
```

Codex can invoke the skill automatically when a task matches its description. You can also invoke it explicitly with `$codex-token-optimizer`.

## Verification

Run the helper around a command whose output needs to be bounded:

```bash
bash scripts/verify.sh --label smoke -- sh -c 'echo "all good"; exit 0'
```

The helper preserves the wrapped command's exit status while keeping logs available under the repository's `.codex/` directory.
