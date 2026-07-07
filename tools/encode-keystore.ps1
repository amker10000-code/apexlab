Param(
    [Parameter(Mandatory=$true)][string]$KeystorePath
)
if (-not (Test-Path $KeystorePath)) {
    Write-Error "Keystore not found: $KeystorePath"
    exit 2
}
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $KeystorePath))
[System.Convert]::ToBase64String($bytes)
