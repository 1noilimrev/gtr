# gtr

Git worktree wrapper with auto-setup for zsh.

## Features

- **Auto-setup**: Creates worktree + links `.env`, `node_modules`, `.venv`
- **Flat directory naming**: Branch `feature/login` → directory `feature-login`
- **AI tool integration**: Run `claude` or `opencode` inside worktrees
- **Idempotent**: Running `gtr add` twice returns existing path
- **Scriptable**: Paths go to stdout, messages to stderr

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/install.sh | sh
```

Then restart your terminal or run `source ~/.zshrc`.

### Manual Installation

```bash
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/gtr.zsh -o ~/.gtr.zsh
echo '[[ -f ~/.gtr.zsh ]] && source ~/.gtr.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Usage

### Create a worktree

```bash
gtr add feature-login
# → Creates .git/worktree-workspace/feature-login/
# → Links .env, node_modules, .venv from main repo
# → Changes to worktree directory
```

### Navigate to worktree

```bash
gtr cd feature-login
```

### Remove worktree

```bash
gtr rm feature-login          # Remove specific worktree
gtr rm -s                     # Remove current worktree
gtr rm -a                     # Remove all worktrees (with confirmation)
gtr rm -a -f                  # Force remove all (no confirmation)
gtr rm -m feature-login       # Merge into main, then remove
```

### Run AI tools in worktree

```bash
gtr claude feature-login
gtr opencode feature-login

# With extra arguments
gtr claude feature-login -- --dangerously-skip-permissions
```

### Merge branches

```bash
gtr merge feature-login           # Merge into main
gtr merge feature-login develop   # Merge into develop
```

### Other commands

```bash
gtr path feature-login    # Get worktree path (stdout only)
gtr --version             # Show version
gtr --help                # Show help
gtr list                  # Passthrough to git worktree list
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `GTR_CLAUDE_CMD` | Command to run for `gtr claude` | `claude` |
| `GTR_CLAUDE_ARGS` | Default args for claude | (none) |
| `GTR_OPENCODE_CMD` | Command to run for `gtr opencode` | `opencode` |
| `GTR_OPENCODE_ARGS` | Default args for opencode | (none) |

### Example: Always use dangerous mode

```bash
export GTR_CLAUDE_ARGS="--dangerously-skip-permissions"
gtr claude feature-login  # Runs: claude --dangerously-skip-permissions
```

## Directory Structure

Worktrees are created in `.git/worktree-workspace/`:

```
my-project/
├── .git/
│   └── worktree-workspace/
│       ├── feature-login/     ← gtr add feature/login
│       └── bugfix-auth/       ← gtr add bugfix/auth
├── .env
├── node_modules/
└── src/
```

Branch names with `/` are converted to `-` for directory names.

## Requirements

- zsh
- git (with worktree support)

## License

MIT
