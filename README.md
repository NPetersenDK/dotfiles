# Dotfiles

Same shell setup on macOS (Bash) and Windows (PowerShell 7): apps, Oh My Posh prompt, `sshi`, `k` alias with kubectl completion.

## Layout

| Path | Purpose |
| --- | --- |
| `Configure-macOS.sh` | Runs Bash, Homebrew and PowerShell setup |
| `Configure-Windows.ps1` | Runs winget, PowerShell and Windows Terminal setup |
| `macos/bash/` | Bash profile |
| `macos/brew/` | Homebrew apps |
| `windows/winget/` | winget apps. Add package IDs to `$AppIds` |
| `windows/terminal/` | Windows Terminal font |
| `common/PowerShell/` | PowerShell profile, `SSHYubi` module |
| `common/oh-my-posh/` | Prompt theme for Bash and PowerShell |

## Setup

macOS:

```bash
bash ./Configure-macOS.sh
```

Windows:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configure-Windows.ps1
```

Open a new terminal afterwards.

Skip steps with flags:

| macOS | Windows | Skips |
| --- | --- | --- |
| `--skip-bash` | | Bash profile |
| `--skip-brew` | `-SkipWinget` | App installation |
| `--skip-powershell` | `-SkipPowerShell` | PowerShell profile, modules (Windows: also terminal) |
| `--skip-modules` | `-SkipModules` | `Az` module |
| | `-SkipTerminal` | Windows Terminal font |

Skipping app installation still needs PowerShell 7 if PowerShell setup runs.

macOS installs Homebrew Bash before configuring it as the login shell. Registering it in `/etc/shells` may require administrator approval. With `--skip-brew`, Homebrew Bash must already be installed. Existing VS Code and Docker Desktop installs are left alone.

## PowerShell profile

`common/PowerShell/Configure-PowerShell.ps1` can run alone in `pwsh`. It:

- Installs `SSHYubi` to `<profile dir>/Modules` and `Az` from PSGallery (current user).
- Replaces the `# >>> Dotfiles >>>` block in `$PROFILE`. Other profile content is kept.
- Prints the logo and `Loaded <module>` only in interactive sessions.

To load another module at startup, add its name to the `foreach` list in the profile block. The module must be at `<profile dir>/Modules/<name>/<name>.psm1`.

## sshi and k

`sshi key user@host [args]` runs `ssh -i ~/.ssh/key`. Tab completes key filenames. Bash and PowerShell.

`k` aliases `kubectl`. Tab completion is enabled when `kubectl` is installed.

## Prompt

Oh My Posh is installed with Homebrew or winget. Setup copies `common/oh-my-posh/theme.omp.json` to `~/.config/dotfiles/theme.omp.json`. Rerun setup after editing the theme. Open a new terminal to see the change.

Line 1: kubectl context/namespace, Azure subscription, .NET SDK (in .NET projects), command time over 2 s. Line 2: user@host, path, Git status. `>` is red after a failed command.

Without `oh-my-posh` in `PATH`, Bash uses a plain prompt and PowerShell its default.

Git tab completion from posh-git is not replaced.

### Font

The theme uses plain-text labels (`k8s:`, `az:`, `dotnet:` and `git:`) and ASCII separators, so a Nerd Font is not required. Setup does not install fonts or delete existing font files.

- Windows Terminal: setup sets `Cascadia Mono` and size 12 in `profiles.defaults.font`. Explicit Caskaydia Nerd Font profile overrides are changed too; other fonts and per-profile sizes are preserved. It writes `settings.json.bak-<timestamp>` first and drops comments from the file.
- macOS Terminal: the standard `SFMono-Regular` font works. VS Code can use its default terminal font.
