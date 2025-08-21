
Kubed Installer (macOS & Windows)

This repository provides scripts to quickly set up kubectl and HashiCorp Vault on both macOS and Windows environments. These scripts automate installation, environment configuration, and path setup for Kubernetes and Vault tools.

📂 Files

install_kubed_mac.sh – Bash script for macOS (Apple Silicon / arm64).

install_kubed_win.ps1 – PowerShell script for Windows (amd64).

🖥 macOS Installation (install_kubed_mac.sh)
What it does

Ensures Homebrew is installed (installs if missing).

Creates a ~/k8s workspace directory.

Installs:

kubectl v1.33.3 (Darwin arm64 binary).

HashiCorp Vault v1.20.2 (arm64 zip).

Adds ~/k8s to your PATH via ~/.zshrc and ~/.bash_profile.

Verifies installs by running kubectl version and vault version.

Provides manual instructions for installing kubectl-wbx3.

Usage
