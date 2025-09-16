Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Config ---
$KubectlVersion = 'v1.30.0'
$VaultVersion   = '1.16.3'

# --- Paths ---
$HomeDir = $env:USERPROFILE
$K8sDir  = Join-Path $HomeDir 'k8s'
$KubectlPath = Join-Path $K8sDir 'kubectl.exe'
$VaultZip = Join-Path $env:TEMP ("vault_{0}_windows_amd64.zip" -f $VaultVersion)
$VaultSha = Join-Path $env:TEMP ("vault_{0}_SHA256SUMS" -f $VaultVersion)

function Stop-Here($Message, [int]$Code = 1) {
  Write-Error $Message
  exit $Code   # use 'return' instead of 'exit' if you do NOT want to close the host
}

# Ensure dir exists
if (-not (Test-Path $K8sDir)) { New-Item -ItemType Directory -Path $K8sDir | Out-Null }

# --- kubectl download & verify ---
Write-Host "Downloading kubectl $KubectlVersion..."
$kubectlUrl = "https://dl.k8s.io/release/$KubectlVersion/bin/windows/amd64/kubectl.exe"
$kubectlShaUrl = "$kubectlUrl.sha256"

try {
  Invoke-WebRequest -Uri $kubectlUrl -OutFile $KubectlPath -UseBasicParsing

  # Corrected line: Convert content to string (UTF8) before trimming
  $expectedKubectlSha = [System.Text.Encoding]::UTF8.GetString((Invoke-WebRequest -Uri $kubectlShaUrl -UseBasicParsing).Content).Trim()

} catch {
  Stop-Here "Failed to download kubectl or its checksum: $($_.Exception.Message)"
}

# Compute local SHA256
$localKubectlSha = (Get-FileHash -Path $KubectlPath -Algorithm SHA256).Hash.ToLower()
if ($localKubectlSha -ne $expectedKubectlSha.ToLower()) {
  Remove-Item $KubectlPath -Force -ErrorAction SilentlyContinue
  Stop-Here "kubectl SHA256 mismatch! expected=$expectedKubectlSha got=$localKubectlSha"
}
Write-Host "✅ kubectl checksum verification PASSED"

# --- Vault download & verify ---
Write-Host "Downloading HashiCorp Vault $VaultVersion..."
$vaultUrl = "https://releases.hashicorp.com/vault/$VaultVersion/vault_${VaultVersion}_windows_amd64.zip"
$shaUrl   = "https://releases.hashicorp.com/vault/$VaultVersion/vault_${VaultVersion}_SHA256SUMS"

try {
  Invoke-WebRequest -Uri $vaultUrl -OutFile $VaultZip -UseBasicParsing
  Invoke-WebRequest -Uri $shaUrl -OutFile $VaultSha -UseBasicParsing
} catch {
  Stop-Here "Failed to download Vault or checksums: $($_.Exception.Message)"
}

# Extract expected SHA for the specific zip filename
$targetFile = "vault_${VaultVersion}_windows_amd64.zip"
$expectedVaultSha = (Select-String -Path $VaultSha -Pattern "([a-fA-F0-9]{64})\s+\*?$([regex]::Escape($targetFile))").Matches.Value.Split()[0]
if (-not $expectedVaultSha) { Stop-Here "Could not find expected SHA for $targetFile in SHA256SUMS." }

# Compute local SHA and compare
$localVaultSha = (Get-FileHash -Path $VaultZip -Algorithm SHA256).Hash.ToLower()
if ($localVaultSha -ne $expectedVaultSha.ToLower()) {
  Remove-Item $VaultZip -Force -ErrorAction SilentlyContinue
  Stop-Here "Vault SHA256 mismatch! expected=$expectedVaultSha got=$localVaultSha"
}
Write-Host "✅ Vault checksum verification PASSED"

# Unzip Vault binary to $K8sDir
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($VaultZip, $K8sDir, $true)

# Clean up temp files
Remove-Item $VaultZip, $VaultSha -Force -ErrorAction SilentlyContinue

# --- PATH (avoid duplicates) ---
$existingUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($existingUserPath -notmatch [regex]::Escape($K8sDir)) {
  [Environment]::SetEnvironmentVariable('Path', "$existingUserPath;$K8sDir", 'User')
  Write-Host "Added $K8sDir to the user PATH. Open a new terminal to pick it up."
} else {
  Write-Host "$K8sDir already on the user PATH."
}

# Make the tools available in the current session immediately
$env:Path = "$env:Path;$K8sDir"

# --- Smoke tests (non-fatal) ---
Write-Host "kubectl version (client):"
try { & $KubectlPath version --client --output=yaml | Select-Object -First 8 | ForEach-Object { $_ } } catch { Write-Warning $_ }
Write-Host "vault version:"
try { & (Join-Path $K8sDir 'vault.exe') --version } catch { Write-Warning $_ }

Write-Host "Done."
