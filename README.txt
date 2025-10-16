# Microsoft PowerShell Projects

A curated set of **PowerShell scripts** for Microsoft ecosystem administration — including **Intune**, **Azure AD**, **Microsoft Graph**, and **Windows** management.  
All scripts are provided as **sanitized templates** (company- and personal-specific data removed) so you can safely adapt them to your environment.

> **Heads-up:** Always review and test in a non-production environment before use.

---

## Contents

- `Get-IntuneUserDeviceReport.ps1` – example reporting script for user ↔ device relationships.
- `Intune_Intranet_Rollout_Script.ps1` – deployment/rollout pattern you can adapt for line-of-business apps or intranet changes.
- `uninstall-adobe-pdf.ps1` – sample remediation/cleanup workflow for uninstalling software.
- `Intune\Kofax\KofaxDetectionScript.ps1` – example detection script structure for app presence/health.
- `Sanitize-Scripts.ps1` – local tool to **make sanitized copies** of your scripts before publishing.

> The above names reflect examples from this repo. Add/remove scripts as your collection grows.

---

## Why this repo?

- Real-world admin tasks distilled into **clean, reusable** PowerShell.
- **Safer sharing:** templates are scrubbed of org-specific details.
- **Learning friendly:** emphasizes structure, error handling, idempotency, and Graph/REST usage patterns.

---

## Getting Started

### Requirements
- Windows PowerShell **5.1** or PowerShell **7.x**
- Recommended:
  - [`Microsoft.Graph`](https://www.powershellgallery.com/packages/Microsoft.Graph) (for Graph API work)
  - [`PSScriptAnalyzer`](https://www.powershellgallery.com/packages/PSScriptAnalyzer) (linting/quality)
  - Execution policy that allows local scripts:  
    `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

### Clone
```powershell
git clone https://github.com/NerdyOreo/Microsoft_Powershell_Projects.git
cd Microsoft_Powershell_Projects
