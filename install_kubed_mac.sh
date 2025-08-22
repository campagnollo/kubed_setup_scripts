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
KUBECTL_URL="https://dl.k8s.io/release/v1.33.3/bin/darwin/arm64/kubectl"
echo "Downloading kubectl..."
curl -fsSL -o kubectl "$KUBECTL_URL"
chmod +x kubectl
export PATH="$HOME/k8s:$PATH"
if ! grep -q 'export PATH="$HOME/k8s:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/k8s:$PATH"' >> "$HOME/.zshrc"
fi
kubectl version --client

# ---- Vault ----
VAULT_ZIP="$HOME/Downloads/vault_1.20.2_darwin_arm64.zip"
echo "Downloading Vault..."
curl -fsSL -o "$VAULT_ZIP" "https://releases.hashicorp.com/vault/1.20.2/vault_1.20.2_darwin_arm64.zip"
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

