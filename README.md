<div align="center">

# 🧠 Microsoft PowerShell Projects
Reusable PowerShell scripts for Microsoft 365, Intune, Azure AD, and Windows automation  
Clean, secure, and fully **sanitized for public sharing**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PowerShell](https://img.shields.io/badge/Language-PowerShell-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![Contributions Welcome](https://img.shields.io/badge/Contributions-Welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Security Policy](https://img.shields.io/badge/Security-Policy-red.svg)](SECURITY.md)

</div>

---

## 📘 Overview

This repository contains **production-tested PowerShell scripts** and patterns for Microsoft ecosystem administration:

- Microsoft Intune & Endpoint Manager  
- Entra ID / Azure Active Directory  
- Microsoft Graph API automation  
- Windows configuration and remediation

All scripts are **sanitized templates** — any company-specific identifiers, credentials, or private information have been removed using the included tool:  
[`Sanitize-Scripts.ps1`](Sanitize-Scripts.ps1)

---

## 📁 Repository Structure

| Folder | Description |
|--------|--------------|
| [`Get-IntuneUserDeviceReport`](Get-IntuneUserDeviceReport/) | Generate reports mapping users ⇄ devices from Intune and Entra ID |
| [`Intune Intranet Rollout`](Intune Intranet Rollout/) | Example rollout/deployment pattern for intranet or LOB content |
| [`KofaxDetection`](KofaxDetection/) | Intune detection script structure for verifying app installs |
| [`RingCentral_Deployment`](RingCentral_Deployment/) | Intune deployment script for silently installing RingCentral via PowerShell |
| [`Sanitize-Scripts.ps1`](Sanitize-Scripts.ps1) | Utility to remove company or personal data from `.ps1` files |
| [`Uninstall-AdobePDF`](Uninstall-AdobePDF/) | Software remediation/uninstall template |
| [`README.md`](README.md) | Main documentation |
| [`LICENSE`](LICENSE) | MIT license |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guidelines |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Contributor behavior standards |
| [`SECURITY.md`](SECURITY.md) | Responsible disclosure and privacy policy |


---

## ⚙️ Requirements

- **PowerShell** 7.x (recommended) or Windows PowerShell 5.1  
- **Execution Policy:** `RemoteSigned` or `Bypass`  
- **Modules:**  
  - [Microsoft.Graph](https://www.powershellgallery.com/packages/Microsoft.Graph)  
  - [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer) *(for linting)*  

---

## 🚀 Quick Start

Clone or download the repo:

```powershell
git clone https://github.com/NerdyOreo/Microsoft_Powershell_Projects.git
cd Microsoft_Powershell_Projects
````

Run any script in test mode:

```powershell
# Example: Run a user-device report
.\Get-IntuneUserDeviceReport\Get-IntuneUserDeviceReport.ps1 -WhatIf
```

---

## 🧹 Using the Sanitizer

The included [`Sanitize-Scripts.ps1`](Sanitize-Scripts.ps1) ensures no private data appears in your code before publishing.

```powershell
# Sanitize specific files
.\Sanitize-Scripts.ps1 -Files @(
  "C:\Scripts\MyScript.ps1"
) -OutputDir "C:\Scripts\Sanitized_PS1"

# Sanitize entire folder
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -OutputDir "C:\Scripts\Sanitized_PS1"

# Dry run
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -WhatIf -OutputDir "C:\Scripts\Sanitized_PS1"
```

Outputs include a `.sanitized.ps1` copy and `.mapping.json/.csv` replacement maps.

---

## 🧰 Recommended Practices

✅ Always test scripts in a **non-production** environment first.
✅ Use `-WhatIf` and `-Confirm:$false` for safe execution.
✅ Follow PowerShell style guidelines (see [`CONTRIBUTING.md`](CONTRIBUTING.md)).
✅ Run `PSScriptAnalyzer` before pushing changes.
✅ Review and sanitize code before publication.

---

## 🤝 Contributing

We welcome improvements!
See the [Contribution Guidelines](CONTRIBUTING.md) for style, testing, and sanitization rules.

1. Fork this repo
2. Create a feature branch
3. Commit your change
4. Open a Pull Request

---

## 🔒 Security

If you find any credential, domain, or sensitive information in the code, please report it **privately** via the instructions in the [Security Policy](SECURITY.md).
Do **not** open public issues for security-related reports.

---

## 🧭 Community Standards

| File                                     | Purpose                           |
| ---------------------------------------- | --------------------------------- |
| [LICENSE](LICENSE)                       | MIT license for open use          |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Contributor expectations          |
| [CONTRIBUTING.md](CONTRIBUTING.md)       | How to safely contribute          |
| [SECURITY.md](SECURITY.md)               | Responsible disclosure policy     |
| [.gitignore](.gitignore)                 | Excludes temp/log/sanitized files |
| [.gitattributes](.gitattributes)         | Normalizes line endings and diffs |

---

## 🪪 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.
© 2025 **Tyler Gates**

---

<div align="center">

💙 *Built for the PowerShell community — secure, clean, and ready to automate.*

</div>
