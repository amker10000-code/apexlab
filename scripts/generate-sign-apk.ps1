<#
.SYNOPSIS
Generate a Java keystore and sign a Capacitor Android APK.

.DESCRIPTION
This helper can create a local Android release keystore and sign the output APK.
It also aligns the signed APK with zipalign.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -GenerateKeystore

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass secret -KeyPass secret
#>

[CmdletBinding()]
param(
    [switch]$GenerateKeystore,
    [switch]$SignApk,
    [string]$KeystorePath,
    [string]$Alias = 'apexlab',
    [int]$Validity = 10000,
    [string]$KeyAlg = 'RSA',
    [int]$KeySize = 2048,
    [string]$UnsignedApk,
    [string]$SignedApk,
    [string]$ZipalignPath,
    [string]$StorePass,
    [string]$KeyPass
)

function Get-ExecutablePath {
    param([Parameter(Mandatory)] [string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Path }

    $candidates = @(
        "C:\Program Files\Android Studio\jbr\bin\$Name.exe",
        "C:\Program Files\Android\Android Studio\jbr\bin\$Name.exe",
        "C:\Program Files\Java\jdk*\bin\$Name.exe",
        "C:\Program Files (x86)\Java\jdk*\bin\$Name.exe"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -like '*jdk*' ) {
            $expanded = Get-ChildItem -Path $candidate -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($expanded) { return $expanded.FullName }
        }
        elseif (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Get-AndroidSdkRoot {
    foreach ($envName in 'ANDROID_SDK_ROOT', 'ANDROID_HOME') {
        $envValue = [Environment]::GetEnvironmentVariable($envName)
        if ($envValue -and (Test-Path $envValue)) {
            return $envValue
        }
    }

    $localProps = Join-Path $repoRoot 'android\local.properties'
    if (Test-Path $localProps) {
        foreach ($line in Get-Content $localProps) {
            if ($line -match '^\s*sdk\.dir\s*=\s*(.+)$') {
                $path = $matches[1]
                $path = $path -replace '\\:', ':'
                $path = $path -replace '\\\\', '\'
                return $path
            }
        }
    }

    return $null
}

function Get-ZipalignPathFromSdk {
    param([Parameter(Mandatory)] [string]$SdkRoot)

    $buildToolsDir = Join-Path $SdkRoot 'build-tools'
    if (-not (Test-Path $buildToolsDir)) {
        return $null
    }

    $candidates = Get-ChildItem -Path $buildToolsDir -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'zipalign.exe' } |
        Where-Object { Test-Path $_ }

    if ($candidates -and $candidates.Count -gt 0) {
        return $candidates |
            Sort-Object { [Version]([Regex]::Match((Split-Path $_ -Parent | Split-Path -Leaf), '\d+(\.\d+)*').Value) } -Descending |
            Select-Object -First 1
    }

    return $null
}

function Convert-SecureStringToPlainText {
    param([Parameter(Mandatory)] [System.Security.SecureString]$SecureString)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -GenerateKeystore"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -SignApk -StorePass '<storepass>' -KeyPass '<keypass>'"
    Write-Host "  powershell -ExecutionPolicy Bypass -File .\scripts\generate-sign-apk.ps1 -GenerateKeystore -SignApk"
    Write-Host ""`
    Write-Host "If you omit -StorePass or -KeyPass the script will prompt for them."
    exit 1
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Resolve-Path "$scriptRoot\.." | Select-Object -ExpandProperty Path

if (-not $GenerateKeystore -and -not $SignApk) {
    Show-Usage
}

if (-not $KeystorePath) {
    $KeystorePath = Join-Path $repoRoot 'release.keystore'
}
if (-not $UnsignedApk) {
    $UnsignedApk = Join-Path $repoRoot 'android\app\build\outputs\apk\release\app-release-unsigned.apk'
}
if (-not $SignedApk) {
    $SignedApk = Join-Path $repoRoot 'android\app\build\outputs\apk\release\app-release.apk'
}

if ($GenerateKeystore) {
    $keytool = Get-ExecutablePath -Name 'keytool'
    if (-not $keytool) {
        Write-Error 'keytool was not found on PATH. Install JDK and try again.'
        exit 1
    }

    if (-not $StorePass) {
        $StorePass = Convert-SecureStringToPlainText (Read-Host 'Enter keystore password' -AsSecureString)
    }
    if (-not $KeyPass) {
        $KeyPass = Convert-SecureStringToPlainText (Read-Host 'Enter key password' -AsSecureString)
    }

    Write-Host "Generating keystore at $KeystorePath"
    & $keytool -genkeypair -v -keystore $KeystorePath -alias $Alias -keyalg $KeyAlg -keysize $KeySize -validity $Validity -storepass $StorePass -keypass $KeyPass
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'Failed to generate keystore.'
        exit $LASTEXITCODE
    }
}

if ($SignApk) {
    $jarsigner = Get-ExecutablePath -Name 'jarsigner'
    if (-not $jarsigner) {
        Write-Error 'jarsigner was not found on PATH. Install JDK and try again.'
        exit 1
    }

    if (-not (Test-Path $UnsignedApk)) {
        Write-Error "Unsigned APK not found at $UnsignedApk. Run the Gradle build first."
        exit 1
    }
    if (-not $StorePass) {
        $StorePass = Convert-SecureStringToPlainText (Read-Host 'Enter keystore password' -AsSecureString)
    }
    if (-not $KeyPass) {
        $KeyPass = Convert-SecureStringToPlainText (Read-Host 'Enter key password' -AsSecureString)
    }

    Write-Host "Signing APK: $UnsignedApk"
    & $jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 -keystore $KeystorePath -storepass $StorePass -keypass $KeyPass $UnsignedApk $Alias
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'jarsigner failed.'
        exit $LASTEXITCODE
    }

    if (-not $ZipalignPath) {
        $ZipalignPath = Get-ExecutablePath -Name 'zipalign'
    }
    if (-not $ZipalignPath) {
        $sdkRoot = Get-AndroidSdkRoot
        if ($sdkRoot) {
            $ZipalignPath = Get-ZipalignPathFromSdk -SdkRoot $sdkRoot
        }
    }

    if (-not $ZipalignPath) {
        Write-Error 'zipalign was not found. Install Android build-tools or set -ZipalignPath explicitly.'
        exit 1
    }

    Write-Host "Aligning signed APK to $SignedApk"
    & $ZipalignPath -v 4 $UnsignedApk $SignedApk
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'zipalign failed.'
        exit $LASTEXITCODE
    }

    Write-Host "Signed APK created: $SignedApk"
}
