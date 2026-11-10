#!/bin/bash
set -euo pipefail

skip_bash=false
skip_brew=false
skip_powershell=false
skip_modules=false
skip_terminal=false

for argument in "$@"; do
    case "$argument" in
        --skip-bash) skip_bash=true ;;
        --skip-brew) skip_brew=true ;;
        --skip-powershell) skip_powershell=true ;;
        --skip-modules) skip_modules=true ;;
        --skip-terminal) skip_terminal=true ;;
        -h|--help)
            printf '%s\n' 'Usage: bash Configure-macOS.sh [--skip-bash] [--skip-brew] [--skip-powershell] [--skip-modules] [--skip-terminal]'
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$argument" >&2
            exit 2
            ;;
    esac
done

if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'This setup script is intended for macOS.' >&2
    exit 1
fi

trap 'printf "\n%s\n" "macOS setup interrupted." >&2; exit 130' INT

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ "$skip_brew" = false ]; then
    /bin/bash "$script_directory/macos/brew/Install-Apps.sh"
else
    printf '%s\n' 'Skipping Homebrew app installation.'
fi

if [ "$skip_bash" = false ]; then
    /bin/bash "$script_directory/macos/bash/Configure-Bash.sh"
else
    printf '%s\n' 'Skipping Bash setup.'
fi

if [ "$skip_powershell" = false ]; then
    if [ "$skip_brew" = false ] || ! command -v pwsh >/dev/null 2>&1; then
        if command -v brew >/dev/null 2>&1; then
            brew_command=$(command -v brew)
        elif [ -x /opt/homebrew/bin/brew ]; then
            brew_command=/opt/homebrew/bin/brew
        elif [ -x /usr/local/bin/brew ]; then
            brew_command=/usr/local/bin/brew
        else
            brew_command=''
        fi
        if [ -n "$brew_command" ]; then
            eval "$("$brew_command" shellenv)"
        fi
    fi

    if ! command -v pwsh >/dev/null 2>&1; then
        printf '%s\n' 'PowerShell 7 was not found. Install it or use --skip-powershell.' >&2
        exit 1b
    fi
    printf '%s\n' 'Starting PowerShell setup...'
    completion_marker=$(mktemp "${TMPDIR:-/tmp}/dotfiles-powershell.XXXXXX")
    trap 'rm -f "$completion_marker"' EXIT
    powershell_arguments=(-NoLogo -NoProfile -File "$script_directory/common/PowerShell/Configure-PowerShell.ps1" -CompletionMarker "$completion_marker")
    if [ "$skip_modules" = true ]; then
        powershell_arguments+=(-SkipModules)
    fi
    pwsh "${powershell_arguments[@]}"
    if ! grep -Fxq 'completed' "$completion_marker"; then
        printf '%s\n' 'PowerShell setup did not complete.' >&2
        exit 1
    fi
    rm -f "$completion_marker"
    trap - EXIT
else
    printf '%s\n' 'Skipping PowerShell setup.'
fi

if [ "$skip_terminal" = false ]; then
    /bin/bash "$script_directory/macos/terminal/Configure-Terminal.sh"
else
    printf '%s\n' 'Skipping macOS Terminal font setup.'
fi

printf '%s\n' 'macOS setup complete.'
if [ "$skip_bash" = false ] || [ "$skip_powershell" = false ]; then
    printf '%s\n' 'Open a new terminal to use the updated shell configuration.'
fi