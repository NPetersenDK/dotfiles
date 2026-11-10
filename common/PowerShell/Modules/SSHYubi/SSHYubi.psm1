function sshi {
    param(
        [string] $KeyName,
        [string] $Destination
    )

    if ([string]::IsNullOrWhiteSpace($KeyName) -or [string]::IsNullOrWhiteSpace($Destination)) {
        throw 'Usage: sshi key-name user@host [ssh arguments...]'
    }
    if ($KeyName -in '.', '..' -or $KeyName -match '[/\\]') {
        throw 'The key must be a filename inside ~/.ssh.'
    }

    $keyPath = Join-Path (Join-Path $HOME '.ssh') $KeyName
    if (-not (Test-Path -LiteralPath $keyPath -PathType Leaf)) {
        throw "SSH key not found: $keyPath"
    }

    & ssh -i $keyPath $Destination @args
}

Register-ArgumentCompleter -CommandName sshi -ParameterName KeyName -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $sshDirectory = Join-Path $HOME '.ssh'
    $prefix = $wordToComplete.TrimStart([char[]] @("'", '"'))
    Get-ChildItem -LiteralPath $sshDirectory -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) } |
        Sort-Object Name |
        ForEach-Object {
            $completionText = "'$( $_.Name.Replace("'", "''") )'"
            [System.Management.Automation.CompletionResult]::new(
                $completionText,
                $_.Name,
                [System.Management.Automation.CompletionResultType]::ParameterValue,
                $_.Name
            )
        }
}

Export-ModuleMember -Function sshi