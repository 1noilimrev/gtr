# gtr

Git worktree wrapper with auto-setup for zsh.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/install.sh | sh
```

## Commands

```bash
gtr add <branch>        # Create worktree (auto-links .env, node_modules, .venv)
gtr cd <branch>         # Navigate to worktree
gtr rm <branch>         # Remove worktree
gtr rm -s               # Remove current worktree (returns to git root)
gtr rm -a [-f]          # Remove all worktrees
gtr rm -m <branch>      # Merge into main, then remove
gtr path <branch>       # Print worktree path
gtr fix [-a] <branch>   # Fix .claude symlink (-a: all)
gtr claude <branch>     # Run claude in worktree
gtr opencode <branch>   # Run opencode in worktree
```

## Notes

- Worktrees are created in `.git/worktree-workspace/`
- Branch `/` converted to `-` in directory names (`feature/foo` → `feature-foo`)
- Auto-links `.env`, `node_modules`, `.venv`, `.claude` from main repo
- Use `-- args` to pass extra arguments to AI tools
- Set `GTR_CLAUDE_ARGS` or `GTR_OPENCODE_ARGS` for default arguments

## License

MIT
