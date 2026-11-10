[CmdletBinding()]
param(
    [string] $FontFace = 'CaskaydiaCove Nerd Font',
    [int] $FontSize = 12
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or later is required. Run this script using pwsh.'
}

$settingsPaths = @(
    Join-Path $env:LOCALAPPDATA 'Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json'
    Join-Path $env:LOCALAPPDATA 'Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json'
    Join-Path $env:LOCALAPPDATA 'Microsoft/Windows Terminal/settings.json'
)

$found = $false
foreach ($settingsPath in $settingsPaths) {
    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        continue
    }
    $found = $true

    try {
        $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json -Depth 100
        if ($settings.profiles -isnot [pscustomobject]) {
            Write-Warning "Skipping $settingsPath because profiles has an unsupported format."
            continue
        }

        if (-not $settings.profiles.PSObject.Properties['defaults']) {
            Add-Member -InputObject $settings.profiles -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{})
        }
        $defaults = $settings.profiles.defaults
        if (-not $defaults.PSObject.Properties['font']) {
            Add-Member -InputObject $defaults -NotePropertyName font -NotePropertyValue ([pscustomobject]@{})
        }
        if ($defaults.font.face -eq $FontFace -and $defaults.font.size -eq $FontSize) {
            Write-Host "Windows Terminal already uses $FontFace $FontSize ($settingsPath)."
            continue
        }

        Add-Member -InputObject $defaults.font -NotePropertyName face -NotePropertyValue $FontFace -Force
        Add-Member -InputObject $defaults.font -NotePropertyName size -NotePropertyValue $FontSize -Force
        $backupPath = "$settingsPath.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -LiteralPath $settingsPath -Destination $backupPath
        $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $settingsPath -Encoding utf8
        Write-Host "Set Windows Terminal font to $FontFace $FontSize ($settingsPath). Backup: $backupPath"
    }
    catch {
        Write-Warning "Could not update ${settingsPath}: $($_.Exception.Message)"
    }
}

if (-not $found) {
    Write-Host 'Windows Terminal settings were not found; skipping.'
}
