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

New-Item -ItemType Directory -Path $profileDirectory -Force | Out-Null
if (-not (Test-Path -LiteralPath $profilePath)) {
    New-Item -ItemType File -Path $profilePath | Out-Null
}

$profileContent = Get-Content -LiteralPath $profilePath -Raw
$profileBlock = @'
# >>> SSHYubi >>>
$sshYubiModule = Join-Path (Join-Path (Split-Path -Path $PROFILE) 'Modules/SSHYubi') 'SSHYubi.psm1'
Import-Module -Name $sshYubiModule
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
# <<< SSHYubi <<<
'@

if ($null -eq $profileContent) {
    $profileContent = ''
}

$profileContent = [regex]::Replace($profileContent, '(?ms)^# >>> SSHYubi >>>\r?\n.*?^# <<< SSHYubi <<<\r?\n?', '')
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