#!/usr/bin/env zsh
# ---------------------------------------------------------------------------------------
# gtr - Git worktree wrapper with auto-setup
#
# All worktrees are created in .git/worktree-workspace/
#
# Usage:
#   gtr add <branch>            Create worktree + auto-checkout + link .env + link node_modules
#   gtr rm <branch>             Remove specified worktree
#       gtr rm -s(--self)       Remove current worktree
#       gtr rm -a(--all)        Remove all worktrees (with confirmation)
#       gtr rm -a -f(--force)   Remove all worktrees (no prompt, ignore uncommitted)
#       gtr rm -m(--merge)      Merge branch before removing
#   gtr cd <branch>             Jump into worktree directory
#   gtr path <branch>           Get worktree path (stdout only)
#   gtr claude <branch> [-- args]   Run claude in worktree
#   gtr opencode <branch> [-- args] Run opencode in worktree
#   gtr merge <src> [target]    Merge source into target (default: main)
#   gtr --version               Show version
#   gtr <git-worktree-cmd>      Fallback to native git worktree commands
#
# Environment Variables:
#   GTR_CLAUDE_CMD              Override claude command (default: claude)
#   GTR_CLAUDE_ARGS             Default args for claude
#   GTR_OPENCODE_CMD            Override opencode command (default: opencode)
#   GTR_OPENCODE_ARGS           Default args for opencode
#
# Note: Branch names with '/' are converted to '-' for directory names
# --------------------------------------------------------------------------------------

GTR_VERSION="0.1.0"

gtr() {
    # Configuration
    local -r WORKTREE_WORKSPACE_DIR=".git/worktree-workspace"
    local -r ENV_FILE=".env"
    local -r NODE_MODULES_DIR="node_modules"
    local -r VENV_DIR=".venv"
    local -r VENV_ALT_DIR="venv"

    # Supported AI tools (extensible)
    local -ra GTR_AI_TOOLS=(claude opencode)

    # =========================================================================
    # Utilities
    # =========================================================================

    __get_git_root() {
        git rev-parse --show-toplevel 2>/dev/null
    }

    __is_worktree() {
        local git_dir
        git_dir=$(git rev-parse --git-dir 2>/dev/null) || return 1
        [[ "$git_dir" == *"/worktrees/"* ]]
    }

    __require_git_repo() {
        if [[ -z "$(__get_git_root)" ]]; then
            echo "error: not a git repository" >&2
            return 1
        fi
        return 0
    }

    __require_branch_name() {
        if [[ -z "$1" ]]; then
            echo "error: branch name required" >&2
            return 1
        fi
        return 0
    }

    # Convert branch name to directory name (/ -> -)
    __branch_to_dirname() {
        echo "${1//\//-}"
    }

    __get_worktree_path() {
        local git_root="$1"
        local branch_name="$2"
        local dirname
        dirname=$(__branch_to_dirname "$branch_name")
        echo "$git_root/$WORKTREE_WORKSPACE_DIR/$dirname"
    }

    __require_worktree_exists() {
        if [[ ! -d "$1" ]]; then
            echo "error: worktree '$2' not found at $1" >&2
            return 1
        fi
        return 0
    }

    __link_env_file() {
        local src="$1/$ENV_FILE"
        local dest="$2/$ENV_FILE"

        if [[ -f "$src" ]]; then
            if ln -s "$src" "$dest" 2>/dev/null; then
                echo "✓ linked $ENV_FILE to worktree" >&2
                return 0
            else
                echo "warning: failed to link $ENV_FILE" >&2
                return 1
            fi
        fi
        return 0
    }

    __link_node_modules() {
        local src="$1/$NODE_MODULES_DIR"
        local dest="$2/$NODE_MODULES_DIR"

        if [[ -d "$src" ]]; then
            if ln -s "$src" "$dest" 2>/dev/null; then
                echo "✓ linked $NODE_MODULES_DIR to worktree" >&2
                return 0
            else
                echo "warning: failed to link $NODE_MODULES_DIR" >&2
                return 1
            fi
        fi
        return 0
    }

    __link_python_venv() {
        local git_root="$1"
        local worktree_dir="$2"

        if [[ -d "$git_root/$VENV_DIR" ]]; then
            if ln -s "$git_root/$VENV_DIR" "$worktree_dir/$VENV_DIR" 2>/dev/null; then
                echo "✓ linked $VENV_DIR to worktree" >&2
                return 0
            else
                echo "warning: failed to link $VENV_DIR" >&2
                return 1
            fi
        elif [[ -d "$git_root/$VENV_ALT_DIR" ]]; then
            if ln -s "$git_root/$VENV_ALT_DIR" "$worktree_dir/$VENV_ALT_DIR" 2>/dev/null; then
                echo "✓ linked $VENV_ALT_DIR to worktree" >&2
                return 0
            else
                echo "warning: failed to link $VENV_ALT_DIR" >&2
                return 1
            fi
        fi
        return 0
    }

    # Check if a tool name is a supported AI tool
    __is_ai_tool() {
        local tool="$1"
        local t
        for t in "${GTR_AI_TOOLS[@]}"; do
            [[ "$t" == "$tool" ]] && return 0
        done
        return 1
    }

    # =========================================================================
    # Commands
    # =========================================================================

    _add() {
        local branch_name="$1"
        shift

        __require_git_repo || return 1
        __require_branch_name "$branch_name" || return 1

        local git_root worktree_dir
        git_root=$(__get_git_root)
        worktree_dir=$(__get_worktree_path "$git_root" "$branch_name")

        # Check if worktree already exists
        if [[ -d "$worktree_dir" ]]; then
            echo "info: worktree '$branch_name' already exists" >&2
            echo "$worktree_dir"
            return 0
        fi

        if ! mkdir -p "$git_root/$WORKTREE_WORKSPACE_DIR"; then
            echo "error: failed to create workspace directory" >&2
            return 1
        fi

        # Handle -b option: if branch exists, use it
        local has_b_option=false
        local target_branch=""
        local args=("$@")
        local new_args=()

        for i in "${!args[@]}"; do
            if [[ "${args[$i]}" == "-b" ]]; then
                has_b_option=true
                target_branch="${args[$((i+1))]}"
            fi
        done

        if $has_b_option && [[ -n "$target_branch" ]]; then
            if git show-ref --verify --quiet "refs/heads/$target_branch" 2>/dev/null; then
                echo "info: branch '$target_branch' exists, using existing branch" >&2
                new_args=("$target_branch")
            else
                new_args=("$@")
            fi
        else
            new_args=("$@")
        fi

        echo "creating worktree: $worktree_dir" >&2
        if ! git worktree add "$worktree_dir" "${new_args[@]}" >/dev/null 2>&1; then
            echo "error: failed to create worktree" >&2
            return 1
        fi

        cd "$worktree_dir" || return 1

        if ! git checkout "$branch_name" 2>/dev/null; then
            echo "warning: could not checkout '$branch_name'" >&2
        fi

        __link_env_file "$git_root" "$worktree_dir"
        __link_node_modules "$git_root" "$worktree_dir"
        __link_python_venv "$git_root" "$worktree_dir"

        echo "→ $worktree_dir" >&2
        echo "$worktree_dir"
        return 0
    }

    _rm() {
        local self_mode=false
        local merge_mode=false
        local all_mode=false
        local force_mode=false
        local merge_target="main"
        local worktree_name=""

        # Parse options
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -s|--self) self_mode=true; shift ;;
                -a|--all) all_mode=true; shift ;;
                -f|--force) force_mode=true; shift ;;
                -m|--merge)
                    merge_mode=true
                    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                        merge_target="$2"
                        shift
                    fi
                    shift
                    ;;
                -*) echo "error: unknown option '$1'" >&2; return 1 ;;
                *) worktree_name="$1"; shift ;;
            esac
        done

        __require_git_repo || return 1

        # All mode: remove all worktrees
        if $all_mode; then
            if $merge_mode; then
                echo "error: -a and -m options cannot be used together" >&2
                return 1
            fi

            local git_root
            git_root=$(__get_git_root)

            local worktree_workspace="$git_root/$WORKTREE_WORKSPACE_DIR"
            if [[ ! -d "$worktree_workspace" ]]; then
                echo "no worktrees found"
                return 0
            fi

            # Get list of worktrees
            local worktrees=()
            for dir in "$worktree_workspace"/*(N/); do
                [[ -d "$dir" ]] && worktrees+=("${dir:t}")
            done

            if [[ ${#worktrees[@]} -eq 0 ]]; then
                echo "no worktrees found"
                return 0
            fi

            echo "found ${#worktrees[@]} worktree(s):"
            for wt in "${worktrees[@]}"; do
                echo "  - $wt"
            done
            echo ""

            # Confirmation prompt (skip if force mode)
            if ! $force_mode; then
                echo -n "remove all worktrees? [y/N] "
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    echo "cancelled"
                    return 0
                fi
            fi

            # If currently in a worktree, move to git root first
            if __is_worktree; then
                echo "moving to git root..."
                cd "$git_root" || return 1
            fi

            local removed=0
            local skipped=0
            for wt in "${worktrees[@]}"; do
                local wt_path="$worktree_workspace/$wt"

                # Check uncommitted changes (skip if force mode)
                if ! $force_mode && [[ -n $(git -C "$wt_path" status --porcelain 2>/dev/null) ]]; then
                    echo "⚠ skipped '$wt' (uncommitted changes)"
                    ((skipped++))
                    continue
                fi

                if git worktree remove --force "$wt_path" 2>/dev/null; then
                    echo "✓ removed '$wt'"
                    ((removed++))
                else
                    echo "✗ failed to remove '$wt'"
                    ((skipped++))
                fi
            done

            echo ""
            echo "done: $removed removed, $skipped skipped"
            return 0
        fi

        # Self mode: remove current worktree
        if $self_mode; then
            if ! __is_worktree; then
                echo "error: not in a worktree" >&2
                return 1
            fi

            local worktree_path worktree_branch
            worktree_path=$(git rev-parse --show-toplevel 2>/dev/null)
            worktree_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

            if [[ "$worktree_branch" == "HEAD" ]]; then
                echo "error: worktree is in detached HEAD state" >&2
                echo "  → create a branch first: git checkout -b <branch>" >&2
                return 1
            fi

            if [[ -n $(git status --porcelain) ]]; then
                echo "error: uncommitted changes in worktree" >&2
                echo "  → commit or stash changes first" >&2
                return 1
            fi

            local git_root
            git_root=$(git rev-parse --git-common-dir 2>/dev/null)
            git_root="${git_root%/.git}"

            if $merge_mode; then
                echo "merging before removal..."
                if ! _merge "$worktree_branch" "$merge_target"; then
                    echo "error: merge failed (you are now at git root on '$merge_target')" >&2
                    echo "  Resolve conflicts, then:" >&2
                    echo "    git merge --continue  # complete merge" >&2
                    echo "    git merge --abort     # cancel merge" >&2
                    echo "  After resolving: gtr rm -s -m $merge_target" >&2
                    echo "  Or skip merge: gtr rm -s" >&2
                    return 1
                fi
            fi

            echo "removing worktree: $worktree_path"
            if ! git worktree remove --force "$worktree_path"; then
                echo "error: failed to remove worktree" >&2
                return 1
            fi

            echo "✓ worktree removed"
            return 0
        fi

        # Named worktree removal
        if [[ -z "$worktree_name" ]]; then
            echo "error: worktree name required (or use -s for current)" >&2
            return 1
        fi

        local git_root worktree_path worktree_branch
        git_root=$(__get_git_root)
        worktree_path=$(__get_worktree_path "$git_root" "$worktree_name")

        __require_worktree_exists "$worktree_path" "$worktree_name" || return 1

        worktree_branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null)

        if [[ "$worktree_branch" == "HEAD" ]]; then
            echo "error: worktree '$worktree_name' is in detached HEAD state" >&2
            return 1
        fi

        if [[ -n $(git -C "$worktree_path" status --porcelain) ]]; then
            echo "error: uncommitted changes in worktree '$worktree_name'" >&2
            echo "  → commit or stash changes first" >&2
            return 1
        fi

        if $merge_mode; then
            echo "merging before removal..."
            if ! _merge "$worktree_branch" "$merge_target"; then
                echo "error: merge failed (you are now at git root on '$merge_target')" >&2
                echo "  Resolve conflicts, then:" >&2
                echo "    git merge --continue  # complete merge" >&2
                echo "    git merge --abort     # cancel merge" >&2
                echo "  After resolving: gtr rm $worktree_name -m $merge_target" >&2
                echo "  Or skip merge: gtr rm $worktree_name" >&2
                return 1
            fi
        fi

        echo "removing worktree: $worktree_path"
        if ! git worktree remove --force "$worktree_path"; then
            echo "error: failed to remove worktree" >&2
            return 1
        fi

        echo "✓ worktree removed"
        return 0
    }

    _cd() {
        local branch_name="$1"

        __require_git_repo || return 1
        __require_branch_name "$branch_name" || return 1

        local git_root worktree_dir
        git_root=$(__get_git_root)
        worktree_dir=$(__get_worktree_path "$git_root" "$branch_name")

        __require_worktree_exists "$worktree_dir" "$branch_name" || return 1

        cd "$worktree_dir" || {
            echo "error: failed to change directory to $worktree_dir" >&2
            return 1
        }

        return 0
    }

    _path() {
        local branch_name="$1"

        __require_git_repo || return 1
        __require_branch_name "$branch_name" || return 1

        local git_root worktree_dir
        git_root=$(__get_git_root)
        worktree_dir=$(__get_worktree_path "$git_root" "$branch_name")

        if [[ -d "$worktree_dir" ]]; then
            echo "$worktree_dir"
            return 0
        else
            echo "error: worktree '$branch_name' not found" >&2
            return 1
        fi
    }

    # Generic AI tool runner
    # Usage: _run_ai_tool <tool_name> <branch_name> [-- extra_args...]
    _run_ai_tool() {
        local tool="$1"
        local branch_name="$2"
        shift 2

        __require_git_repo || return 1
        __require_branch_name "$branch_name" || return 1

        local git_root worktree_dir
        git_root=$(__get_git_root)
        worktree_dir=$(__get_worktree_path "$git_root" "$branch_name")

        __require_worktree_exists "$worktree_dir" "$branch_name" || return 1

        # Get tool-specific env vars (GTR_CLAUDE_CMD, GTR_CLAUDE_ARGS, etc.)
        local tool_upper="${tool:u}"  # zsh uppercase
        local cmd_var="GTR_${tool_upper}_CMD"
        local args_var="GTR_${tool_upper}_ARGS"

        # Use indirect expansion to get env var values
        local cmd="${(P)cmd_var:-$tool}"
        local default_args="${(P)args_var:-}"

        # Parse extra args (after --)
        local extra_args=()
        local found_separator=false
        for arg in "$@"; do
            if [[ "$arg" == "--" ]]; then
                found_separator=true
                continue
            fi
            if $found_separator; then
                extra_args+=("$arg")
            fi
        done

        # Check if command exists
        if ! command -v "${cmd%% *}" >/dev/null 2>&1; then
            echo "error: '$cmd' command not found" >&2
            echo "  → install $tool or set GTR_${tool_upper}_CMD" >&2
            return 1
        fi

        # Run tool in worktree
        (
            cd "$worktree_dir" || exit 1
            # Build command with args
            if [[ -n "$default_args" ]] && [[ ${#extra_args[@]} -gt 0 ]]; then
                eval "$cmd $default_args ${extra_args[*]}"
            elif [[ -n "$default_args" ]]; then
                eval "$cmd $default_args"
            elif [[ ${#extra_args[@]} -gt 0 ]]; then
                eval "$cmd ${extra_args[*]}"
            else
                eval "$cmd"
            fi
        )

        return $?
    }

    _merge() {
        local source_branch="$1"
        local target_branch="${2:-main}"

        __require_git_repo || return 1
        __require_branch_name "$source_branch" || return 1

        if ! git rev-parse --verify "$source_branch" >/dev/null 2>&1; then
            echo "error: source branch '$source_branch' not found" >&2
            return 1
        fi

        if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
            echo "error: target branch '$target_branch' not found" >&2
            return 1
        fi

        if [[ "$source_branch" == "$target_branch" ]]; then
            echo "error: cannot merge branch into itself" >&2
            return 1
        fi

        local git_root git_common_dir
        git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
        if [[ "$git_common_dir" == ".git" ]]; then
            git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        else
            git_root="${git_common_dir%/.git}"
        fi

        cd "$git_root" || return 1

        echo "checking out '$target_branch'..." >&2
        if ! git checkout "$target_branch"; then
            echo "error: failed to checkout '$target_branch'" >&2
            return 1
        fi

        if [[ -n $(git status --porcelain) ]]; then
            echo "error: uncommitted changes in '$target_branch'" >&2
            echo "  → commit or stash changes before merging" >&2
            return 1
        fi

        echo "merging '$source_branch' into '$target_branch'..." >&2
        if ! git merge "$source_branch"; then
            echo "error: merge failed" >&2
            echo "  Resolve conflicts manually, then:" >&2
            echo "    git merge --continue  # to complete merge" >&2
            echo "    git merge --abort     # to cancel merge" >&2
            return 1
        fi

        echo "✓ merged '$source_branch' into '$target_branch'" >&2
        return 0
    }

    _version() {
        echo "gtr $GTR_VERSION"
    }

    _help() {
        cat >&2 <<EOF
gtr $GTR_VERSION - Git worktree wrapper with auto-setup

USAGE:
    gtr <command> [options]

COMMANDS:
    add <branch> [opts]         Create new worktree (idempotent)
    rm <branch>                 Remove worktree
        -s, --self              Remove current worktree
        -a, --all               Remove all worktrees
        -f, --force             Force remove (skip confirmation/uncommitted check)
        -m, --merge [target]    Merge branch before removing (default: main)
    cd <branch>                 Change to worktree directory
    path <branch>               Get worktree path (stdout only)
    claude <branch> [-- args]   Run claude in worktree
    opencode <branch> [-- args] Run opencode in worktree
    merge <src> [target]        Merge src into target (default: main)

OPTIONS:
    -v, --version               Show version
    -h, --help                  Show this help

ENVIRONMENT:
    GTR_CLAUDE_CMD              Override claude command (default: claude)
    GTR_CLAUDE_ARGS             Default args for claude
    GTR_OPENCODE_CMD            Override opencode command (default: opencode)
    GTR_OPENCODE_ARGS           Default args for opencode

NOTES:
    - Branch names with '/' are converted to '-' for directory names
    - Worktrees are created in .git/worktree-workspace/
    - Any unknown commands are passed to 'git worktree'
EOF
        return 0
    }

    # =========================================================================
    # Command Router
    # =========================================================================

    local command="$1"
    shift 2>/dev/null

    case "$command" in
        add)
            _add "$@"
            ;;
        rm)
            _rm "$@"
            ;;
        cd)
            _cd "$@"
            ;;
        path)
            _path "$@"
            ;;
        merge)
            _merge "$@"
            ;;
        -v|--version)
            _version
            ;;
        -h|--help|help)
            _help
            ;;
        "")
            _help
            return 1
            ;;
        *)
            # Check if it's an AI tool command
            if __is_ai_tool "$command"; then
                _run_ai_tool "$command" "$@"
            else
                # Fallback to git worktree
                git worktree "$command" "$@"
            fi
            ;;
    esac
}
