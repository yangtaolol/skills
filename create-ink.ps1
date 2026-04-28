param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SourcePath,

    [Parameter(Mandatory = $true, Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$TargetPaths
)

$ErrorActionPreference = "Stop"

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path).Path)
}

if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
    throw "Source path not found or not a directory: $SourcePath"
}

$sourceFull = Resolve-FullPath -Path $SourcePath
Write-Host "Source: $sourceFull"

foreach ($targetPath in $TargetPaths) {
    $targetParent = Split-Path -Parent $targetPath
    if ([string]::IsNullOrWhiteSpace($targetParent)) {
        $targetParent = "."
    }

    if (-not (Test-Path -LiteralPath $targetParent -PathType Container)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    if (Test-Path -LiteralPath $targetPath) {
        $item = Get-Item -LiteralPath $targetPath -Force
        $isReparsePoint = ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0

        if ($isReparsePoint) {
            Remove-Item -LiteralPath $targetPath -Force
            Write-Host "[INFO] Replaced existing link: $targetPath"
        } else {
            throw "Target exists and is not a link: $targetPath"
        }
    }

    New-Item -ItemType Junction -Path $targetPath -Target $sourceFull | Out-Null
    Write-Host "[DONE] $targetPath -> $sourceFull"
}

Write-Host "Completed."
