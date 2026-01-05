# gtr (DEPRECATED)

> **⚠️ This project has been renamed to `gwt`. Please migrate to the new package.**

## Migration

Run the migration script to switch from `gtr` to `gwt`:

```bash
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/migrate.sh | sh
```

Or manually:

```bash
# Uninstall gtr
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gtr/main/uninstall.sh | sh

# Install gwt
curl -fsSL https://raw.githubusercontent.com/1noilimrev/gwt/main/install.sh | sh
```

## New Repository

The active development continues at: **[gwt](https://github.com/1noilimrev/gwt)**

All commands remain the same, just use `gwt` instead of `gtr`:

```bash
gwt add <branch>        # Create worktree
gwt cd <branch>         # Navigate to worktree
gwt rm <branch>         # Remove worktree
gwt rm -s               # Remove current worktree
gwt rm -a [-f]          # Remove all worktrees
gwt rm -m <branch>      # Merge into main, then remove
gwt path <branch>       # Print worktree path
gwt claude <branch>     # Run claude in worktree
gwt opencode <branch>   # Run opencode in worktree
```

## License

MIT
