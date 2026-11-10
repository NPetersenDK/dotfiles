#!/bin/bash
set -euo pipefail

if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'Terminal font setup is intended for macOS.' >&2
    exit 1
fi

# Terminal uses the PostScript font name, not the family name.
font_name='CaskaydiaCoveNFM-Regular'
font_size=13
terminal_columns=120
printf '%s\n' 'Checking CaskaydiaCove Nerd Font Mono...'
osascript -l AppleScript - "$font_name" <<'EOF'
use framework "AppKit"
on run arguments
    set selectedFont to current application's NSFont's fontWithName:(item 1 of arguments) |size|:12
    if selectedFont is missing value then
        error "CaskaydiaCove Nerd Font Mono is missing. Run brew install --cask font-caskaydia-cove-nerd-font first."
    end if
end run
EOF

backup_directory="$HOME/.config/dotfiles/backups"
mkdir -p "$backup_directory"
backup_path=$(mktemp "$backup_directory/Terminal.XXXXXX")
defaults export com.apple.Terminal "$backup_path" >/dev/null
printf 'Configuring Terminal font and width (backup: %s)...\n' "$backup_path"
osascript - "$font_name" "$font_size" "$terminal_columns" <<'EOF'
on run arguments
    set fontName to item 1 of arguments
    set fontSize to (item 2 of arguments) as integer
    set terminalColumns to (item 3 of arguments) as integer
    tell application "Terminal"
        set font name of default settings to fontName
        set font name of startup settings to fontName
        set font size of default settings to fontSize
        set font size of startup settings to fontSize
        set number of columns of default settings to terminalColumns
        set number of columns of startup settings to terminalColumns
        repeat with terminalWindow in windows
            repeat with terminalTab in tabs of terminalWindow
                set font name of terminalTab to fontName
                set font size of terminalTab to fontSize
            end repeat
            set number of columns of terminalWindow to terminalColumns
        end repeat
    end tell
end run
EOF
printf 'Terminal now uses CaskaydiaCove Nerd Font Mono at %s pt and %s columns.\n' "$font_size" "$terminal_columns"