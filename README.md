# Dotfiles

App installation and shell configuration for macOS and Windows. Includes an Oh My Posh theme, SSH key completion and a `k` alias for `kubectl`.

## Layout

| Path | Purpose |
| --- | --- |
| `Configure-macOS.sh` | Runs Homebrew, Bash, PowerShell and Terminal setup |
| `Configure-Windows.ps1` | Runs winget, PowerShell and Windows Terminal setup |
| `macos/bash/` | Bash profile |
| `macos/brew/` | Homebrew apps |
| `macos/terminal/` | Terminal font, size and window width |
| `windows/winget/` | winget apps |
| `windows/terminal/` | Windows Terminal font |
| `common/PowerShell/` | PowerShell profile, `SSHYubi` module |
| `common/oh-my-posh/` | Prompt theme for Bash and PowerShell |

## Setup

Run from the repository root. Setup installs missing apps and updates the shell profiles. Other profile content is preserved.

### macOS

```bash
bash ./Configure-macOS.sh
```

Homebrew installs Bash before it is set as the login shell. Registering Bash in `/etc/shells` requires administrator approval. Terminal font changes may require permission to control Terminal.

Existing VS Code and Docker Desktop installations are kept. The Docker formula installs only the CLI, not a local daemon.

### Windows

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configure-Windows.ps1
```

Requires winget from App Installer when apps need to be checked or installed. The entry script can run in Windows PowerShell 5.1; profile and Terminal setup run in PowerShell 7. Profile loading follows your Windows execution policy.

Open a new terminal after setup on either platform.

### Skip steps

Skip steps with flags:

| macOS | Windows | Skips |
| --- | --- | --- |
| `--skip-bash` | | Bash profile |
| `--skip-brew` | `-SkipWinget` | App installation |
| `--skip-powershell` | `-SkipPowerShell` | PowerShell profile, modules (Windows: also terminal) |
| `--skip-modules` | `-SkipModules` | `Az` module |
| `--skip-terminal` | `-SkipTerminal` | Terminal font settings |

`--skip-modules` and `-SkipModules` skip PSGallery installation, not local modules or fonts.

With app installation skipped, PowerShell 7 must already be installed if its setup runs. On macOS, Bash setup also needs Homebrew Bash, and Terminal setup needs the Nerd Font.

Add Homebrew packages to `formulae` or `casks` in `macos/brew/Install-Apps.sh`. Add winget IDs to `$AppIds` in `windows/winget/Install-Apps.ps1`.

## PowerShell profile

Run separately in PowerShell 7:

```powershell
./common/PowerShell/Configure-PowerShell.ps1 -SkipModules
```

The script:

- Copies `SSHYubi` to `<profile dir>/Modules` and the theme to `~/.config/dotfiles`.
- Installs `Az` from PSGallery for the current user unless `-SkipModules` is set.
- Installs the Nerd Font on Windows if missing.
- Updates the `# >>> Dotfiles >>>` block in `$PROFILE` without replacing other content.
- Shows the startup logo and module name when output is interactive and not redirected.

To load another module at startup, add its name to the `foreach` list in the profile block. The module must be at `<profile dir>/Modules/<name>/<name>.psm1`.

## sshi and k

`sshi key user@host [args]` runs `ssh -i ~/.ssh/key user@host [args]` in Bash and PowerShell. Tab completes filenames in `~/.ssh`. Normal SSH configuration still applies.

`k` aliases `kubectl`. Completion is loaded when `kubectl` is available at shell startup.

## Prompt

Oh My Posh is installed through Homebrew or winget. Both shells use `~/.config/dotfiles/theme.omp.json`, copied from `common/oh-my-posh/theme.omp.json`. Rerun shell setup after editing the theme, then open a new terminal.

- First line: Kubernetes context and namespace, Azure subscription, .NET SDK in .NET projects, and commands taking over two seconds.
- Second line: user, host, path and Git status. The final `>` turns red after a failed command.

Without `oh-my-posh` in `PATH`, Bash uses a plain prompt and PowerShell its default.

### Font

The theme requires `CaskaydiaCove Nerd Font Mono` for its icons and Powerline separators. Git uses the standard Oh My Posh status format: `?` untracked, `+` added, `~` modified and `-` deleted.

- macOS: Homebrew installs `font-caskaydia-cove-nerd-font`. Terminal setup sets 13 pt and 120 columns for default/startup profiles and open windows. It exports the previous preferences to `~/.config/dotfiles/backups/Terminal.*` first.
- Windows: PowerShell setup runs `oh-my-posh font install CascadiaCode` if needed. Terminal setup selects the Mono face at 12 pt. It also updates explicit Caskaydia Nerd Font and Cascadia Mono overrides, preserving other fonts and per-profile sizes. A `settings.json.bak-<timestamp>` backup is saved first. Rewriting the JSON removes comments.
- VS Code: set `terminal.integrated.fontFamily` to `CaskaydiaCove Nerd Font Mono` in user settings. Setup does not modify VS Code settings.
