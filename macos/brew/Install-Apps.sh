#!/bin/bash
set -euo pipefail

if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'Homebrew setup is intended for macOS.' >&2
    exit 1
fi

printf '%s\n' 'Checking Homebrew...'
if command -v brew >/dev/null 2>&1; then
    brew_command=$(command -v brew)
elif [ -x /opt/homebrew/bin/brew ]; then
    brew_command=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
    brew_command=/usr/local/bin/brew
else
    printf '%s\n' 'Installing Homebrew...'
    installer=$(mktemp "${TMPDIR:-/tmp}/homebrew-install.XXXXXX")
    trap 'rm -f "$installer"' EXIT
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
    /bin/bash "$installer"
    rm -f "$installer"
    trap - EXIT
    if [ -x /opt/homebrew/bin/brew ]; then
        brew_command=/opt/homebrew/bin/brew
    elif [ -x /usr/local/bin/brew ]; then
        brew_command=/usr/local/bin/brew
    else
        printf '%s\n' 'Homebrew was installed but brew could not be found.' >&2
        exit 1
    fi
fi

printf '%s\n' 'Homebrew is available.'
eval "$("$brew_command" shellenv)"
formulae=(bash git go azure-cli kubectl helm copilot-cli docker oh-my-posh)
for formula in "${formulae[@]}"; do
    printf 'Checking %s... ' "$formula"
    if [ "$formula" = docker ] &&
       { command -v docker >/dev/null 2>&1 || [ -d '/Applications/Docker.app' ] || [ -d "$HOME/Applications/Docker.app" ]; }; then
        printf '%s\n' 'already installed.'
        if ! command -v docker >/dev/null 2>&1; then
            printf '%s\n' 'Docker Desktop was found, but the docker command is not in PATH.'
        fi
        continue
    fi
    if "$brew_command" list --formula "$formula" >/dev/null 2>&1; then
        printf '%s\n' 'already installed.'
    else
        printf '%s\n' 'installing.'
        "$brew_command" install "$formula"
        printf '%s installed.\n' "$formula"
    fi
done
printf '%s' 'Checking powershell... '
if "$brew_command" list --formula powershell >/dev/null 2>&1 ||
   "$brew_command" list --cask powershell >/dev/null 2>&1; then
    printf '%s\n' 'already installed.'
else
    printf '%s\n' 'installing.'
    "$brew_command" install powershell
    printf '%s\n' 'powershell installed.'
fi
casks=(visual-studio-code claude-code alt-tab)
for cask in "${casks[@]}"; do
    printf 'Checking %s... ' "$cask"
    if [ "$cask" = visual-studio-code ] &&
       { [ -d '/Applications/Visual Studio Code.app' ] || [ -d "$HOME/Applications/Visual Studio Code.app" ]; }; then
        printf '%s\n' 'already installed.'
        continue
    fi
    if "$brew_command" list --cask "$cask" >/dev/null 2>&1; then
        printf '%s\n' 'already installed.'
    else
        printf '%s\n' 'installing.'
        "$brew_command" install --cask "$cask"
        printf '%s installed.\n' "$cask"
    fi
done