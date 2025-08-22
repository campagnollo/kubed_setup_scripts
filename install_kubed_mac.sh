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

#!/usr/bin/env bash
set -euo pipefail

VERSION="v1.33.4"
OS="darwin"
ARCH="arm64"
BIN="kubectl"

BASE="https://dl.k8s.io/release/${VERSION}/bin/${OS}/${ARCH}"
DEST_DIR="$HOME/k8s/bin"
DEST="$DEST_DIR/$BIN"

TMP="$(mktemp -d)"
cleanup(){ rm -rf "$TMP"; }
trap cleanup EXIT

echo "Downloading $BIN $VERSION for $OS/$ARCH…"
curl -fsSL -o "$TMP/$BIN"         "$BASE/$BIN"
curl -fsSL -o "$TMP/$BIN.sha256"  "$BASE/$BIN.sha256"

echo "Verifying SHA256…"
(
  cd "$TMP"
  if command -v sha256sum >/dev/null 2>&1; then
    # Linux style
    echo "$(cat $BIN.sha256)  $BIN" | sha256sum -c -
  else
    # macOS style
    echo "$(cat $BIN.sha256)  $BIN" | shasum -a 256 --check -
  fi
)

echo "Installing to $DEST…"
mkdir -p "$DEST_DIR"
install -m 0755 "$TMP/$BIN" "$DEST"

# Add to PATH once
RC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/k8s/bin:$PATH"'
if ! grep -Fq "$PATH_LINE" "$RC" 2>/dev/null; then
  echo "$PATH_LINE" >> "$RC"
  ADDED_PATH=1
fi

echo "Done."
"$DEST" version --client
[[ "${ADDED_PATH:-0}" == "1" ]] && echo 'Note: PATH updated. Restart your shell or `source ~/.zshrc`.'


# ---- Vault ----
#!/usr/bin/env bash
set -euo pipefail

VERSION="1.20.2"
OS="darwin"
ARCH="arm64"
NAME="vault"

PKG="${NAME}_${VERSION}_${OS}_${ARCH}.zip"
BASE="https://releases.hashicorp.com/${NAME}/${VERSION}"

DEST_DIR="$HOME/k8s/bin"
DEST="$DEST_DIR/${NAME}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading ${PKG}…"
curl -fsSL -o "$TMP/$PKG" "$BASE/$PKG"
curl -fsSL -o "$TMP/${NAME}_${VERSION}_SHA256SUMS" "$BASE/${NAME}_${VERSION}_SHA256SUMS"
curl -fsSL -o "$TMP/${NAME}_${VERSION}_SHA256SUMS.sig" "$BASE/${NAME}_${VERSION}_SHA256SUMS.sig"

# Optional: verify HashiCorp signature on the checksums if gpg is available
if command -v gpg >/dev/null 2>&1; then
  echo "Verifying HashiCorp GPG signature on SHA256SUMS…"
  # HashiCorp Security key fingerprint:
  # 91A6 E7F8 5D05 C656 30BE  F189 5185 2D87 348F FC4C
  if ! gpg --list-keys 51852D87348FFC4C >/dev/null 2>&1; then
    gpg --keyserver hkps://keys.openpgp.org    --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C || \
    gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C
  fi
  gpg --verify "$TMP/${NAME}_${VERSION}_SHA256SUMS.sig" "$TMP/${NAME}_${VERSION}_SHA256SUMS"
else
  echo "gpg not found; skipping signature verification."
fi

echo "Verifying SHA256 for ${PKG}…"
(
  cd "$TMP"
  grep " ${PKG}\$" "${NAME}_${VERSION}_SHA256SUMS" > CHECKSUM
  shasum -a 256 --check CHECKSUM
)

echo "Unzipping…"
unzip -qo "$TMP/$PKG" -d "$TMP"

echo "Installing to $DEST…"
mkdir -p "$DEST_DIR"
install -m 0755 "$TMP/$NAME" "$DEST"

RC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/k8s/bin:$PATH"'
if ! grep -Fq "$PATH_LINE" "$RC" 2>/dev/null; then
  echo "$PATH_LINE" >> "$RC"
  ADDED_PATH=1
fi

echo "Done."
"$DEST" version
[[ "${ADDED_PATH:-0}" == "1" ]] && echo 'Note: PATH updated. Restart your shell or `source ~/.zshrc`.'



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
