#!/usr/bin/env bash
set -euo pipefail

# Ensure Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."

  # Xcode CLT (needed by Homebrew)
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install || true
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "$HOME/.zshrc"
  echo 'export PATH="/opt/homebrew/bin:$PATH"' >> "$HOME/.bash_profile"
  export PATH="/opt/homebrew/bin:$PATH"
else
  echo "Homebrew is installed: $(brew --version | head -n1)"
fi

# Workspace
mkdir -p "$HOME/k8s"
cd "$HOME/k8s"

# ---- kubectl (Darwin arm64) ----
VERSION="v1.33.4"
OS="darwin"
ARCH="arm64"

KUBECTL_URL="https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}/kubectl"
KUBECTL_SHA256_URL="https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}/kubectl.sha256"
echo "Downloading kubectl..."
curl -fsSL -o kubectl "$KUBECTL_URL"
curl -fsSL -o kubectl.sha256 "$KUBECTL_SHA256_URL"

echo "Verifying SHA256…"
if echo "$(cat kubectl.sha256)  kubectl" | shasum -a 256 --check --status -; then
  echo "Kubectl checksum ok."
else
  echo "Kubectl failed checksum. Exiting." >&2
  exit
fi


chmod +x kubectl
export PATH="$HOME/k8s:$PATH"
if ! grep -q 'export PATH="$HOME/k8s:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/k8s:$PATH"' >> "$HOME/.zshrc"
fi
kubectl version --client

# ---- Vault ----
VERSION="1.20.2"
OS="darwin"
ARCH="arm64"
VAULT_ZIP="$HOME/Downloads/vault_1.20.2_darwin_arm64.zip"
VAULT_256SUMS="$HOME/Downloads/vault_${VERSION}_SHA256SUMS"
echo "Downloading Vault..."
curl -fsSL -o "$VAULT_ZIP" "https://releases.hashicorp.com/vault/$VERSION/vault_${VERSION}_${OS}_${ARCH}.zip"
curl -fsSL -o "$VAULT_256SUMS" "https://releases.hashicorp.com/vault/$VERSION/vault_${VERSION}_SHA256SUMS"

EXPECTED_SHA=$(grep "vault_${VERSION}_${OS}_${ARCH}.zip" "$VAULT_256SUMS" | awk '{print $1}')
if echo "${EXPECTED_SHA}  $VAULT_ZIP" | shasum -a 256 --check --status -; then
  echo "Vault checksum ok."
else
  echo "Vault failed checksum. Exiting." >&2
  exit
fi

ditto -xk "$VAULT_ZIP" "$HOME/k8s"
chmod +x "$HOME/k8s/vault"
vault version


#---- make the k8s folder accessible ------
echo 'export PATH="$HOME/k8s:$PATH"' >> ~/.zshrc
source ~/.zshrc


# ---- kubectl-wbx3 ----
echo "****************"
echo "For kubectl-wbx3, you must manually access the site:"
echo "https://sqbu-github.cisco.com/WebexPlatform/kubectl-wbx3/releases/tag/v1.3.3"
echo "After downloading, unzip the file, move to k8s /User/<username>/folder"
echo "Verify with kubectl-wbx3"
echo ""
echo "✅ Setup complete"

