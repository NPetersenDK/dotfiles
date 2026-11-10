#!/bin/bash
set -euo pipefail

if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'This setup script is intended for macOS.' >&2
    exit 1
fi

printf '%s\n' 'Configuring Bash profile...'
mkdir -p "$HOME/.config/dotfiles"
cat > "$HOME/.config/dotfiles/bashrc" <<'EOF'
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

sshi() {
    if [ "$#" -lt 2 ]; then
        printf '%s\n' 'Usage: sshi key-name user@host [ssh arguments...]' >&2
        return 2
    fi

    local key_name=$1
    shift
    case "$key_name" in
        ''|.|..|*/*)
            printf '%s\n' 'The key must be a filename inside ~/.ssh.' >&2
            return 2
            ;;
    esac

    local key_path="$HOME/.ssh/$key_name"
    if [ ! -f "$key_path" ]; then
        printf 'SSH key not found: %s\n' "$key_path" >&2
        return 1
    fi

    command ssh -i "$key_path" "$@"
}

_sshi_complete() {
    COMPREPLY=()
    [ "$COMP_CWORD" -eq 1 ] || return 0

    local prefix=${COMP_WORDS[COMP_CWORD]}
    local key_path key_name
    for key_path in "$HOME/.ssh/"* "$HOME/.ssh/".*; do
        [ -f "$key_path" ] || continue
        key_name=${key_path##*/}
        case "$key_name" in
            "$prefix"*) COMPREPLY+=("$key_name") ;;
        esac
    done
}

complete -o filenames -F _sshi_complete sshi

alias k=kubectl
if [[ $- == *i* ]] && command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -o default -F __start_kubectl k
fi

case $- in
    *i*) PS1='\u@\h:\w\$ ' ;;
esac
EOF

touch "$HOME/.bashrc" "$HOME/.bash_profile"
if ! grep -Fxq '# >>> dotfiles bashrc >>>' "$HOME/.bashrc"; then
    printf '\n%s\n' '# >>> dotfiles bashrc >>>' \
        '[ -f "$HOME/.config/dotfiles/bashrc" ] && . "$HOME/.config/dotfiles/bashrc"' \
        '# <<< dotfiles bashrc <<<' >> "$HOME/.bashrc"
fi
if ! grep -Fxq '# >>> dotfiles login >>>' "$HOME/.bash_profile"; then
    printf '\n%s\n' '# >>> dotfiles login >>>' \
        '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"' \
        '# <<< dotfiles login <<<' >> "$HOME/.bash_profile"
fi

current_shell=$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')
if [ "$current_shell" != /bin/bash ]; then
    printf '%s\n' 'Changing your macOS login shell to /bin/bash.'
    chsh -s /bin/bash
else
    printf '%s\n' 'Login shell: /bin/bash is already configured.'
fi

printf '%s\n' 'Bash setup complete.'