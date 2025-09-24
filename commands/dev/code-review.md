### Review current Git changes (staged and unstaged)

Please review the current changes in this repo for correctness, clarity, potential bugs, security issues, and missing tests/docs. Be concise and high-signal. Prioritize risky diffs.

Provide feedback on:
- Correctness and edge cases
- Code style/consistency
- Performance and security risks
- Duplicated code: re-implementations of existing utilities, or repeated snippets in this change
- Low-signal comments: change narrations or noise (e.g., "I changed X to Y")
- Test coverage and docs gaps

Context to use:
- Staged diff: output of `git diff --staged | cat`
- Unstaged diff: output of `git diff | cat`
- Optional: `git status -sb | cat` for a quick overview

Deliverables:
- A short summary of key findings
- Specific, actionable suggestions grouped by file

