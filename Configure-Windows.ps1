[CmdletBinding()]
param(
    [switch] $SkipWinget,
    [switch] $SkipPowerShell,
    [switch] $SkipModules
)

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'This setup script is intended for Windows.'
}

if (-not $SkipWinget) {
    Write-Host 'Checking Windows apps...'
    & (Join-Path $PSScriptRoot 'windows/winget/Install-Apps.ps1')
}
else {
    Write-Host 'Skipping winget app installation.'
}

if (-not $SkipPowerShell) {
    $defaultPwshPath = Join-Path $env:ProgramFiles 'PowerShell/7/pwsh.exe'
    $pwshCommand = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue
    $pwshPaths = @($defaultPwshPath)
    if ($pwshCommand) {
        $pwshPaths += $pwshCommand.Source
    }

    $pwshPath = $null
    foreach ($candidate in $pwshPaths) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            & $candidate -NoLogo -NoProfile -NonInteractive -Command 'if ($PSVersionTable.PSVersion.Major -lt 7) { exit 1 }'
            if ($LASTEXITCODE -eq 0) {
                $pwshPath = $candidate
                break
            }
        }
    }

    if (-not $pwshPath) {
        throw 'PowerShell 7 was not found. Install it or use -SkipPowerShell.'
    }

    $configurationScript = Join-Path $PSScriptRoot 'common/PowerShell/Configure-PowerShell.ps1'
    $pwshArguments = @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $configurationScript)
    if ($SkipModules) {
        $pwshArguments += '-SkipModules'
    }
    Write-Host 'Starting PowerShell setup...'
    & $pwshPath @pwshArguments
    if ($LASTEXITCODE -ne 0) {
        throw "PowerShell configuration failed (exit code $LASTEXITCODE)."
    }
}
else {
    Write-Host 'Skipping PowerShell setup.'
}

Write-Host 'Windows setup complete.'
if (-not $SkipPowerShell) {
    Write-Host 'Open a new PowerShell 7 session to use sshi.'
}