Here’s a clean `README.md` you can place in your GitHub repo alongside your two installer scripts. It explains what the scripts do, their requirements, and how to run them.

````markdown
# Kubernetes & Vault Installer Scripts

This repository contains installation scripts for setting up **kubectl** and **Vault** on macOS and Windows.  
The scripts automate the installation of dependencies and configure your environment for Kubernetes development.

---

## 📂 Files

- `install_kubed_mac.sh` – Bash script for macOS (Apple Silicon / arm64)
- `install_kubed_win.ps1` – PowerShell script for Windows

---

## 🚀 Features

- Installs **Homebrew** (macOS only, if not present)
- Installs **kubectl** (v1.33.3)
- Installs **HashiCorp Vault** (v1.20.2)
- Creates a `~/k8s` workspace directory
- Updates your shell configuration (`.zshrc` / `.bash_profile`) to include Kubernetes tools in your `PATH`
- Provides guidance for manually installing `kubectl-wbx3` (Cisco Webex Platform CLI extension)

---

## 🖥️ macOS Installation

1. Make the script executable:
   ```bash
   chmod +x install_kubed_mac.sh
````

2. Run the script:

   ```bash
   ./install_kubed_mac.sh
   ```

3. Restart your terminal or reload your shell config:

   ```bash
   source ~/.zshrc
   ```

---

## 🪟 Windows Installation

1. Open **PowerShell as Administrator**.
2. Run the script:

   ```powershell
   ./install_kubed_win.ps1
   ```

---

## ⚠️ Notes

* `kubectl-wbx3` must be downloaded manually from the Cisco internal GitHub:
  [kubectl-wbx3 v1.3.3 release](https://sqbu-github.cisco.com/WebexPlatform/kubectl-wbx3/releases/tag/v1.3.3)
  After downloading, unzip and move it into your `~/k8s` folder.

* Ensure your terminal session picks up updated environment variables (`PATH`) after installation.

---

## ✅ Verification

Run the following commands to verify installation:

```bash
kubectl version --client
vault version
```

On Windows PowerShell:

```powershell
kubectl version --client
vault version
```

---

## 📜 License

This project is provided **as-is** for internal setup purposes.
Modify and use at your own discretion.

```

Would you like me to also add **badges** (like version, shell type, or supported OS) and a **quick start table** at the top, to make the README look more polished for GitHub?
```
