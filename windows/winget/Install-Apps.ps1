[CmdletBinding()]
param(
    [string[]] $AppIds = @(
        'Microsoft.PowerShell'
        'Git.Git'
        'GoLang.Go'
        'Microsoft.AzureCLI'
        'Kubernetes.kubectl'
        'Helm.Helm'
        'Anthropic.ClaudeCode'
        'GitHub.Copilot'
        'Microsoft.VisualStudioCode'
        'JanDeDobbeleer.OhMyPosh'
    )
)

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'winget setup is intended for Windows.'
}

Write-Host 'Checking for PowerShell 7...'
$pwshCommand = Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue
$defaultPwshPath = Join-Path $env:ProgramFiles 'PowerShell/7/pwsh.exe'
$pwshPaths = @($defaultPwshPath)
if ($pwshCommand) {
    $pwshPaths += $pwshCommand.Source
}

$powerShellInstalled = $false
foreach ($pwshPath in $pwshPaths) {
    if (Test-Path -LiteralPath $pwshPath -PathType Leaf) {
        & $pwshPath -NoLogo -NoProfile -NonInteractive -Command 'if ($PSVersionTable.PSVersion.Major -lt 7) { exit 1 }'
        if ($LASTEXITCODE -eq 0) {
            $powerShellInstalled = $true
            break
        }
    }
}

foreach ($appId in $AppIds) {
    Write-Host -NoNewline "Checking $appId... "
    if ($appId -eq 'Microsoft.PowerShell' -and $powerShellInstalled) {
        Write-Host 'already installed.'
        continue
    }

    $wingetCommand = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        throw 'winget was not found. Install or update App Installer from the Microsoft Store.'
    }

    $installedPackages = & $wingetCommand.Source list --id $appId --exact --source winget --accept-source-agreements --disable-interactivity
    $packagePattern = '(^|\s)' + [regex]::Escape($appId) + '(\s|$)'
    if ($LASTEXITCODE -eq 0 -and ($installedPackages | Where-Object { $_ -match $packagePattern })) {
        Write-Host 'already installed.'
        continue
    }

    Write-Host 'installing.'
    & $wingetCommand.Source install --id $appId --exact --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install $appId (exit code $LASTEXITCODE)."
    }
    Write-Host "$appId installed."
}