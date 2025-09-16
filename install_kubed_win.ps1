# ------------------- Config -------------------
$VaultVersion = "1.16.3"                                # set/override if your script already defines it
$VaultFile    = "vault_${VaultVersion}_windows_amd64.zip"
$VaultUrl     = "https://releases.hashicorp.com/vault/$VaultVersion/$VaultFile"

$TempDir  = $env:TEMP
$VaultZip = Join-Path $TempDir $VaultFile               # e.g. C:\Users\<you>\AppData\Local\Temp\vault_1.16.3_windows_amd64.zip
# If you download a .sha256 or have a known hash, set one of these:
# $VaultShaFile = "$VaultZip.sha256"
# $VaultSha256  = "<expected_sha256_hex>"

# Root install dir (keep previous installs under here)
# (Assumes you already set $K8sDir elsewhere; if not, uncomment next line)
# $K8sDir = "$HOME\k8s"
New-Item -ItemType Directory -Path $K8sDir -Force | Out-Null

# Destination subfolder per install (keeps prior installs)
# Prefer a version-based folder; fall back to timestamp if missing
$releaseTag = $VaultVersion
if ([string]::IsNullOrWhiteSpace($releaseTag)) { $releaseTag = Get-Date -Format 'yyyyMMdd-HHmmss' }
$DestDir = Join-Path $K8sDir "vault_$releaseTag"
New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

# ------------------- Helpers -------------------
function Invoke-DownloadWithRetry {
    param(
        [Parameter(Mandatory)]
        [string] $Uri,
        [Parameter(Mandatory)]
        [string] $OutFile,
        [int] $Retries = 3,
        [int] $DelaySec = 3
    )
    for ($i = 1; $i -le $Retries; $i++) {
        try {
            Write-Host "Downloading ($i/$Retries): $Uri -> $OutFile"
            # Ensure target folder exists
            New-Item -ItemType Directory -Force -Path (Split-Path $OutFile -Parent) | Out-Null

            $wc = New-Object System.Net.WebClient
            # Helpful UA for some CDNs
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 PowerShell")
            $wc.DownloadFile($Uri, $OutFile)
            Remove-Variable wc -ErrorAction SilentlyContinue

            if (!(Test-Path $OutFile)) { throw "Download reported success, but file not found: $OutFile" }
            $fi = Get-Item $OutFile
            if ($fi.Length -lt 1024) { throw "Downloaded file is suspiciously small ($($fi.Length) bytes): $OutFile" }

            return $true
        } catch {
            if ($i -eq $Retries) { throw }
            Start-Sleep -Seconds $DelaySec
        }
    }
}

function Test-FileSha256 {
    param(
        [Parameter(Mandatory)]
        [string] $Path,
        [string] $ExpectedSha256,   # hex string
        [string] $ShaFilePath       # optional *.sha256 file path
    )
    if (!(Test-Path $Path)) { throw "Cannot hash missing file: $Path" }

    if ($ShaFilePath -and (Test-Path $ShaFilePath)) {
        # Parse "<sha>  filename" or just "<sha>"
        $line = (Get-Content -Raw -Path $ShaFilePath).Trim()
        $parts = $line -split '\s+'
        if ($parts[0]) { $ExpectedSha256 = $parts[0] }
    }

    if (-not $ExpectedSha256) { return $true } # nothing to verify
    $hash = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    return ($hash -eq $ExpectedSha256.ToLowerInvariant())
}

function Extract-Zip {
    param(
        [Parameter(Mandatory)]
        [string] $ZipPath,
        [Parameter(Mandatory)]
        [string] $TargetDir
    )
    if (!(Test-Path $ZipPath))   { throw "Zip not found: $ZipPath" }
    if (!(Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Try 3-arg overload (Encoding) first for filename safety; fallback to 2-arg for PS 5.1 environments
    try {
        [IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TargetDir, [System.Text.Encoding]::UTF8)
    } catch {
        [IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TargetDir)
    }
}
# ------------------- Workflow -------------------

# 1) Download (with retries)
if (!(Test-Path $VaultZip)) {
    Invoke-DownloadWithRetry -Uri $VaultUrl -OutFile $VaultZip -Retries 3 -DelaySec 3
} else {
    Write-Host "Using existing zip: $VaultZip"
}

# 2) Verify presence (explicit check prevents your old error)
if (!(Test-Path $VaultZip)) {
    throw "Vault zip not found after download attempt: $VaultZip"
}

# 3) Optional: verify SHA256 (if you have either $VaultSha256 or a sidecar sha file)
$ok = $true
try {
    $ok = Test-FileSha256 -Path $VaultZip -ExpectedSha256 $VaultSha256 -ShaFilePath $VaultShaFile
} catch { throw }
if (-not $ok) {
    Remove-Item $VaultZip -Force -ErrorAction SilentlyContinue
    throw "SHA256 verification failed for $VaultZip"
}

# 4) Extract (to versioned folder; prior installs retained)
Extract-Zip -ZipPath $VaultZip -TargetDir $DestDir

# 5) (Optional) Update a 'current' junction to this version
$currentLink = Join-Path $K8sDir "current"
if (Test-Path $currentLink) { Remove-Item $currentLink -Force }
New-Item -ItemType Junction -Path $currentLink -Target $DestDir | Out-Null

# 6) Clean up only temp artifacts you don't need
#    (If you prefer to keep the zip for auditing, comment the next line)
Remove-Item $VaultZip, $VaultShaFile -Force -ErrorAction SilentlyContinue

Write-Host "Vault installed to: $DestDir"
Write-Host "current -> $DestDir"
