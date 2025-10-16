# Intune_Intranet_Rollout_Script.ps1

A **PowerShell deployment template** for automating **intranet content or configuration rollouts** through Microsoft Intune or direct endpoint automation.

> 🧩 This script is a sanitized version — safe for public sharing.  
> Replace example paths, registry keys, or file names with values that fit your environment.

---

## 📋 Overview

This script provides a **repeatable rollout pattern** for distributing files, registry changes, or shortcuts across managed Windows endpoints.  
It’s designed for **Intune Win32 apps**, **endpoint deployment**, or local automation tasks where consistency, logging, and rollback are key.

---

## 🚀 Features

- Creates **backups** of existing files or registry values  
- Deploys updated **intranet files**, shortcuts, or configurations  
- Supports **dry-run (`-WhatIf`) mode** for safety  
- Modular and reusable for future deployments  
- Generates optional **detailed logs**

---

## ⚙️ Requirements

| Requirement | Description |
|--------------|-------------|
| **PowerShell** | 7.x or Windows PowerShell 5.1 |
| **Execution Policy** | `RemoteSigned` or `Bypass` |
| **Admin Rights** | Required when modifying protected system paths or registry hives |
| **Optional** | Microsoft Intune for distribution / detection integration |

---

## 🧠 Parameters

| Parameter | Type | Description |
|------------|------|-------------|
| `ConfigPath` | String | Path to a JSON config file with file, shortcut, and registry mappings |
| `BackupPath` | String | Destination folder for backups (default: `%ProgramData%\IntranetBackup`) |
| `VerboseLog` | Switch | Enable verbose console output and logs |
| `WhatIf` | Switch | Simulate rollout without making changes |

---

## 🧾 Example Configuration File

`config\example-settings.json`

```json
{
  "Files": [
    {
      "Source": ".\\payload\\Home.html",
      "Destination": "C:\\Intranet\\Home.html"
    }
  ],
  "Shortcuts": [
    {
      "Path": "C:\\Users\\Public\\Desktop\\Intranet.lnk",
      "Target": "C:\\Intranet\\Home.html"
    }
  ],
  "Registry": [
    {
      "Path": "HKLM:\\Software\\Contoso\\Intranet",
      "Name": "Enabled",
      "Type": "DWord",
      "Value": 1
    }
  ]
}
````

---

## 💻 Usage Examples

```powershell
# 1. Preview the rollout
.\Intune_Intranet_Rollout_Script.ps1 -ConfigPath ".\config\example-settings.json" -WhatIf

# 2. Execute with logging
.\Intune_Intranet_Rollout_Script.ps1 -ConfigPath ".\config\example-settings.json" -VerboseLog

# 3. Deploy silently (for Intune)
powershell.exe -ExecutionPolicy Bypass -File .\Intune_Intranet_Rollout_Script.ps1
```

---

## 🧱 Intune Integration

* **Package** this script using the Intune Win32 packaging tool.
* **Detection Script:** check for file/registry existence and version.
* **Remediation Script:** use this rollout script for remediation.
* Schedule via **proactive remediation** or **Win32 app** deployments.

---

## 🗃 Logging & Backup

* Backups created automatically at `$BackupPath`
* Logs written under:

  ```
  C:\ProgramData\IntranetRollout\Logs\
  ```
* Use these for validation or rollback after testing.

---

## 🧩 Tips & Best Practices

* Always run in `-WhatIf` mode before production rollout.
* Keep rollout JSON files versioned for traceability.
* Use `Try / Catch` with error codes for consistent Intune detection.
* Keep backups small — purge after validation.

---

## 🧰 Related References

* [Microsoft Intune Win32 App Packaging Tool](https://learn.microsoft.com/mem/intune/apps/apps-win32-app-management)
* [PowerShell File and Registry Providers](https://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-providers)
* [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer)

---

## 🪪 License

MIT License © 2025 Tyler Gates
Provided *as-is*, without warranty or affiliation with Microsoft.

```
