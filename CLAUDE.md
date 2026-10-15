# Nono & Fofo

## Git workflow (every chat)

- **Start of every chat:** before making any file changes, create a new branch from the latest default branch:
  1. `git fetch origin` and check out the default branch, then pull it.
  2. `git checkout -b <type>/<short-kebab-description>` (e.g. `feat/sound-board`, `fix/map-audio-loop`), named after the task in the first message.
  - If the session is already on a non-default branch created for this chat (or in a worktree the app made), use it instead of creating another.
- **Work on that branch only.** Commit as you go with clear messages. Never commit directly to the default branch.
- **When the user says the task is completed** (e.g. "done", "task completed", "ship it"), do this automatically, without asking for confirmation:
  1. Commit any remaining changes.
  2. `git push -u origin <branch>`.
  3. Open a PR into the default branch with `gh pr create`. Give it a clear title and a body that summarizes what changed and why.
  4. Reply with the PR link.
- Don't open a PR before the user says the task is completed.
