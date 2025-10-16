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
````

### Run a script (example)

```powershell
# Example: run a report script
.\Get-IntuneUserDeviceReport.ps1 -WhatIf
```

> Most scripts support a `-WhatIf` or dry-run pattern. Check the top-of-file comments for details and parameters.

---

## Sanitizing your own scripts (included tool)

This repo includes **`Sanitize-Scripts.ps1`**, which makes sanitized copies of `.ps1` files **without modifying the originals**.
It also writes a `.mapping.json` and `.mapping.csv` so you can see what changed.

**Examples**

```powershell
# Sanitize specific files → writes to .\Sanitized_PS1
.\Sanitize-Scripts.ps1 -Files @(
  "C:\Path\Script1.ps1",
  "C:\Path\Script2.ps1"
) -OutputDir "C:\Path\Sanitized_PS1"

# Sanitize an entire folder (recursively)
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -OutputDir "C:\Scripts\Sanitized"

# Dry run (no files written)
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -WhatIf -OutputDir "C:\Scripts\Sanitized"
```

**What it replaces (high level)**

* Emails, UPNs, domains/hostnames (with whitelist), IPv4, MACs, GUIDs, URLs, UNC paths
* Credential-like pairs and connection strings
* JWT/Bearer tokens, SAS params, long Base64 blobs
* Azure IDs (tenant/subscription/client) and Resource IDs
* LDAP DNs
* Company name terms you specify (see `-CompanyNamePatterns`)

> Tip: Add public domains to the whitelist so they aren’t replaced (e.g. `microsoft.com`, `github.com`).

---

## Script Quality Tips

* **Run PSScriptAnalyzer**

  ```powershell
  Install-Module PSScriptAnalyzer -Scope CurrentUser
  Invoke-ScriptAnalyzer -Path . -Recurse -Fix -Settings Default
  ```
* **Use SecureString/SecretManagement** instead of hard-coded secrets.
* **Parameterize** scripts; avoid environment-specific constants in code.
* Prefer **idempotent** operations for deployments/remediations.
* Add **`-WhatIf`** and **`-Confirm:$false`** patterns where meaningful.

---

## Contributing

Contributions are welcome!
Please open an **issue** or **PR** with:

* a short description of the change
* how you tested it
* any prerequisites (modules/permissions)

Coding style: align to PowerShell best practices (`PSScriptAnalyzer`), use CmdletBinding/advanced functions for new scripts, and include examples in comment-based help.

---

## License & Disclaimer

MIT License — see `LICENSE`.
This repository is **not affiliated with Microsoft**. All scripts are provided **as-is** without warranty. Review code and test before production use.

---

## Acknowledgments

Thanks to the PowerShell community and Microsoft docs for patterns and references. If your script builds on someone’s public work, please credit them in the header comments.

```

