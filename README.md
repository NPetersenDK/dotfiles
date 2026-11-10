# Dotfiles

## Structure

- `Configure-macOS.sh`: runs the macOS Bash, Homebrew and shared PowerShell setup.
- `Configure-Windows.ps1`: runs the Windows winget and shared PowerShell setup.
- `macos/bash/`: Bash profile, prompt and `sshi` configuration.
- `macos/brew/`: Homebrew, Git, Go, Azure CLI, kubectl, Helm, PowerShell, Copilot CLI, Docker CLI, VS Code, Claude Code and AltTab installation.
- `windows/winget/`: PowerShell 7, Git, Go, Azure CLI, kubectl, Helm, Claude Code, GitHub Copilot and VS Code installation.
- `common/PowerShell/`: shared PowerShell setup and module.

## macOS setup

Run `bash ./Configure-macOS.sh` in a macOS terminal. It installs Homebrew if necessary, installs the apps listed above, changes the macOS login shell to `/bin/bash`, and sets a `username@hostname` Bash prompt. The Docker formula provides the CLI, not a Docker daemon or Docker Desktop. Homebrew and the shell change can request confirmation or authentication. A terminal configured to use a custom shell may need its own settings changed to use the login shell.

Use `--skip-bash`, `--skip-brew`, `--skip-powershell` or `--skip-modules` to skip individual steps. `--skip-modules` skips PSGallery module installation while still configuring the PowerShell profile. Flags can be combined:

```bash
bash ./Configure-macOS.sh --skip-brew --skip-powershell
bash ./Configure-macOS.sh --skip-brew --skip-modules
```

If Visual Studio Code already exists in `/Applications` or `~/Applications`, setup leaves that installation untouched; Homebrew does not manage its updates.

If Docker Desktop or an existing `docker` command is found, setup skips the Docker formula. Homebrew does not manage an existing Docker Desktop installation.

The script preserves existing Bash profile content and adds `sshi` for keys in `~/.ssh`. Press Tab after `sshi` to complete a key filename:

```bash
sshi key1 user@1.2.3.4
```

The macOS entry point also configures PowerShell. Open a new terminal after setup.

## Windows setup

Run the entry point from Windows PowerShell or PowerShell 7:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configure-Windows.ps1
```

Use `-SkipWinget`, `-SkipPowerShell` or `-SkipModules` to skip individual steps; the switches can be combined. `-SkipModules` skips PSGallery module installation while still configuring the PowerShell profile:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configure-Windows.ps1 -SkipWinget
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configure-Windows.ps1 -SkipWinget -SkipModules
```

When skipping Homebrew or winget but running PowerShell setup, PowerShell 7 must already be installed.

The script requires winget (App Installer) to install a missing PowerShell 7 or check additional listed applications. It installs PowerShell 7 if necessary and runs the shared setup using `pwsh`. Open a new PowerShell 7 session after setup. Loading the profile remains subject to your Windows execution policy.

Add more winget package IDs to the `$AppIds` array in `windows/winget/Install-Apps.ps1` to include additional applications in Windows setup.

## Shared PowerShell setup

Both platform entry points install the local `SSHYubi` module and, if missing, the `Az` module from PSGallery for the current user. PSGallery installation requires network access. To run the shared setup separately from PowerShell 7:

```powershell
./common/PowerShell/Configure-PowerShell.ps1
```

The script installs the module in `$(Split-Path $PROFILE)/Modules/SSHYubi`, creates `$PROFILE` if it does not exist, and adds a managed Dotfiles block to the normal profile. The block imports the module, making `sshi` available. Existing profile content is preserved on later runs, and the block is replaced each time the script runs (an older block named SSHYubi is removed).

When PowerShell starts in an interactive terminal, the block prints `Loaded <module>` on its own line for each module it imports, and the PETERSEN logo last. Nothing is printed when the output is redirected, so scripts that start `pwsh` are not affected. To load another module at startup, add its name to the `foreach ($moduleName in 'SSHYubi')` list in `common/PowerShell/Configure-PowerShell.ps1`; the module must be in `$(Split-Path $PROFILE)/Modules/<name>/<name>.psm1`.

Use the filename of a key directly inside `~/.ssh`, just as in Bash. Press Tab after `sshi` to complete a key filename:

```powershell
sshi key1 user@1.2.3.4
```

OpenSSH still applies its normal configuration and host-key checks.

In both Bash and PowerShell, `k` is an alias for `kubectl`. When `kubectl` is available at shell startup, its tab completion is enabled for both commands.