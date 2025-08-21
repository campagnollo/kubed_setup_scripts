# PowerShell script to install kubectl and HashiCorp Vault for Windows

# Stop on errors
$ErrorActionPreference = "Stop"

# --- Config ---
$KubectlVersion = "v1.30.0"
$VaultVersion   = "1.16.3"   # change as desired

# --- Paths ---
$HomeDir = $env:USERPROFILE
$K8sDir  = Join-Path $HomeDir "k8s"
$VaultZip = Join-Path $HomeDir ("Downloads/vault_{0}_windows_amd64.zip" -f $VaultVersion)
$VaultSha = Join-Path $HomeDir ("Downloads/vault_{0}_SHA256SUMS" -f $VaultVersion)

# Ensure k8s dir exists
if (-not (Test-Path $K8sDir)) { New-Item -ItemType Directory -Path $K8sDir | Out-Null }

# --- kubectl ---
Write-Host "Downloading kubectl $KubectlVersion..."
Invoke-WebRequest -Uri "https://dl.k8s.io/release/$KubectlVersion/bin/windows/amd64/kubectl.exe" -OutFile (Join-Path $K8sDir "kubectl.exe")
Write-Host "kubectl installed to $K8sDir"

# --- Vault ---
Write-Host "Downloading HashiCorp Vault $VaultVersion..."
$vaultUrl = "https://releases.hashicorp.com/vault/$VaultVersion/vault_${VaultVersion}_windows_amd64.zip"
$shaUrl   = "https://releases.hashicorp.com/vault/$VaultVersion/vault_${VaultVersion}_SHA256SUMS"
Invoke-WebRequest -Uri $vaultUrl -OutFile $VaultZip
Invoke-WebRequest -Uri $shaUrl -OutFile $VaultSha

# Verify checksum
Write-Host "Verifying Vault checksum..."
$expectedHashLine = Get-Content $VaultSha | Where-Object { $_ -match "vault_${VaultVersion}_windows_amd64.zip" }
if (-not $expectedHashLine) { throw "Checksum line not found for Vault zip" }
$expectedHash = $expectedHashLine.Split(' ')[0]

$actualHash = (Get-FileHash $VaultZip -Algorithm SHA256).Hash.ToLower()
if ($expectedHash.ToLower() -ne $actualHash) {
    throw "Vault checksum verification FAILED. Expected $expectedHash but got $actualHash"
} else {
    Write-Host "Vault checksum verification PASSED"
}

Write-Host "Extracting Vault..."
Expand-Archive -Path $VaultZip -DestinationPath $K8sDir -Force
Remove-Item $VaultZip -ErrorAction SilentlyContinue
Remove-Item $VaultSha -ErrorAction SilentlyContinue

# --- PATH Update (User) ---
$pathUser = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathMachine = [Environment]::GetEnvironmentVariable('Path', 'Machine')

$inUser = ($pathUser -split ';') -contains $K8sDir
$inMachine = ($pathMachine -split ';') -contains $K8sDir

if (-not $inUser -and -not $inMachine) {
    $newUserPath = if ([string]::IsNullOrWhiteSpace($pathUser)) { $K8sDir } else { $pathUser.TrimEnd(';') + ";" + $K8sDir }
    [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
    Write-Host "Added $K8sDir to your *User* PATH. New terminals will pick this up."
} else {
    Write-Host "$K8sDir is already on PATH."
}

# Update PATH for current process so this terminal can use the tools immediately
$env:Path = ($pathMachine + ';' + $pathUser)

# --- Verify ---
Write-Host "kubectl version (client):"
try { & (Join-Path $K8sDir "kubectl.exe") version --client --output=yaml | Select-Object -First 5 | ForEach-Object { $_ } } catch { Write-Warning $_ }

Write-Host "vault version:"
try { & (Join-Path $K8sDir "vault.exe") --version } catch { Write-Warning $_ }

Write-Host "Done. If commands aren't found in a *new* terminal, sign out and back in to refresh PATH propagation."
