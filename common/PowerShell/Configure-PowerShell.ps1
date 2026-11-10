[CmdletBinding()]
param(
    [switch] $SkipModules,
    [string] $CompletionMarker
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or later is required. Run this script using pwsh.'
}

$galleryModules = @('Az')
if ($SkipModules) {
    Write-Host 'Skipping PSGallery module installation.'
}
else {
    foreach ($moduleName in $galleryModules) {
        Write-Host -NoNewline "Checking PowerShell module $moduleName... "
        if (Get-Module -ListAvailable -Name $moduleName) {
            Write-Host 'already installed.'
            continue
        }

        Write-Host 'installing from PSGallery. This may take several minutes.'
        Install-Module -Name $moduleName -Repository PSGallery -Scope CurrentUser -Force
        Write-Host "Installed $moduleName from PSGallery for the current user."
    }
}

$moduleSource = Join-Path $PSScriptRoot 'Modules/SSHYubi'
Write-Host 'Configuring PowerShell profile and SSHYubi...'
$profilePath = $PROFILE
$profileDirectory = Split-Path -Path $profilePath
$moduleRoot = Join-Path $profileDirectory 'Modules'
$moduleDestination = Join-Path $moduleRoot 'SSHYubi'

if (-not (Test-Path -LiteralPath $moduleSource -PathType Container)) {
    throw "SSHYubi module source was not found: $moduleSource"
}
New-Item -ItemType Directory -Path $moduleDestination -Force | Out-Null
Copy-Item -Path (Join-Path $moduleSource '*') -Destination $moduleDestination -Recurse -Force

$themeSource = Join-Path $PSScriptRoot '../oh-my-posh/theme.omp.json'
$themeDirectory = Join-Path $HOME '.config/dotfiles'
if (-not (Test-Path -LiteralPath $themeSource -PathType Leaf)) {
    throw "Oh My Posh theme was not found: $themeSource"
}
New-Item -ItemType Directory -Path $themeDirectory -Force | Out-Null
Copy-Item -LiteralPath $themeSource -Destination (Join-Path $themeDirectory 'theme.omp.json') -Force

New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $profilePath)) {
    New-Item -ItemType File -Path $profilePath | Out-Null
}

$profileContent = Get-Content -LiteralPath $profilePath -Raw
$profileBlock = @'
# >>> Dotfiles >>>
# Skip the banner when output is redirected.
$showStartup = [Environment]::UserInteractive -and -not [Console]::IsOutputRedirected

foreach ($moduleName in 'SSHYubi') {
    $modulePath = Join-Path (Join-Path (Join-Path (Split-Path -Path $PROFILE) 'Modules') $moduleName) "$moduleName.psm1"
    Import-Module -Name $modulePath
    if ($showStartup) {
        Write-Host "Loaded $moduleName"
    }
}

Set-Alias -Name k -Value kubectl -Scope Global -Force
if (Get-Command kubectl -CommandType Application -ErrorAction SilentlyContinue) {
    $kubectlCompletion = kubectl completion powershell | Out-String
    if ($LASTEXITCODE -eq 0 -and $kubectlCompletion) {
        Invoke-Expression $kubectlCompletion
        $kubectlCompleter = Get-Variable -Name __kubectlCompleterBlock -ValueOnly -ErrorAction SilentlyContinue
        if ($kubectlCompleter) {
            Register-ArgumentCompleter -CommandName k -ScriptBlock $kubectlCompleter
        }
    }
}

if (Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config (Join-Path $HOME '.config/dotfiles/theme.omp.json') | Invoke-Expression
}

if ($showStartup) {
    $petersenLogo = @(
        '     ____  _____ _____ _____ ____  ____  _____ _   _ '
        '    |  _ \| ____|_   _| ____|  _ \/ ___|| ____| \ | |'
        '    | |_) |  _|   | | |  _| | |_) \___ \|  _| |  \| |'
        '    |  __/| |___  | | | |___|  _ < ___) | |___| |\  |'
        '    |_|   |_____| |_| |_____|_| \_|____/|_____|_| \_|'
    )
    Write-Host ''
    Write-Host ($petersenLogo -join [Environment]::NewLine) -ForegroundColor Green
    Write-Host ''
}
# <<< Dotfiles <<<
'@

if ($null -eq $profileContent) {
    $profileContent = ''
}

# Replace the managed block. The old SSHYubi block name is removed too.
$profileContent = [regex]::Replace($profileContent, '(?ms)^# >>> (?:Dotfiles|SSHYubi) >>>\r?\n.*?^# <<< (?:Dotfiles|SSHYubi) <<<\r?\n?', '')
if ($profileContent.Length -gt 0 -and -not $profileContent.EndsWith("`n")) {
    $profileContent += [Environment]::NewLine
}
$profileContent += $profileBlock + [Environment]::NewLine
Set-Content -LiteralPath $profilePath -Value $profileContent -NoNewline -Encoding utf8

Import-Module -Name (Join-Path $moduleDestination 'SSHYubi.psm1') -Global -Force
Set-Alias -Name k -Value kubectl -Scope Global -Force

Write-Host "Installed SSHYubi to $moduleDestination"
Write-Host "PowerShell profile: $profilePath"
Write-Host 'Loaded SSHYubi in the current PowerShell session'
if ($CompletionMarker) {
    Set-Content -LiteralPath $CompletionMarker -Value 'completed' -Encoding utf8
}