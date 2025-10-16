# uninstall-adobe-pdf.ps1

A **PowerShell remediation template** for cleanly uninstalling Adobe PDF products — adaptable to any other software removal scenario.

> 🧩 This version is fully sanitized for public sharing.  
> Replace the example product names, GUIDs, or uninstall strings with those that match your environment.

---

## 📋 Overview

This script is a **safe, idempotent uninstall routine** commonly used in Intune, ConfigMgr, or local automation.  
It checks whether a target application (in this case Adobe PDF software) is installed, attempts removal, and logs its actions and results.

---

## 🚀 Features

- Detects installed software by **registry key**, **WMI**, or **WinGet** query  
- Performs **graceful uninstalls** (using vendor strings or MSI product codes)  
- Falls back to **silent uninstall** modes when possible  
- Returns **exit codes** for Intune or task sequence logic  
- Supports **`-WhatIf`** mode for dry runs  
- Generates **log output** for audit and troubleshooting

---

## ⚙️ Requirements

| Requirement | Description |
|--------------|-------------|
| **PowerShell** | 7.x or Windows PowerShell 5.1 |
| **Permissions** | Local admin rights on target endpoint |
| **Execution Policy** | `RemoteSigned` or `Bypass` |
| **Optional** | Intune or ConfigMgr for distribution and remediation management |

---

## 🧠 Parameters

| Parameter | Type | Description |
|------------|------|-------------|
| `ProductName` | String | Partial product name to search for (default: `"Adobe Acrobat"`) |
| `Force` | Switch | Attempt removal even if detection fails |
| `WhatIf` | Switch | Preview uninstall actions without executing |
| `Verbose` | Switch | Detailed console and log output |

---

## 💻 Usage Examples

```powershell
# 1. Preview uninstall (no changes)
.\uninstall-adobe-pdf.ps1 -WhatIf

# 2. Full uninstall with verbose logging
.\uninstall-adobe-pdf.ps1 -ProductName "Adobe Acrobat" -Verbose

# 3. Force remove any detected Adobe PDF variant
.\uninstall-adobe-pdf.ps1 -ProductName "Adobe" -Force
````

---

## 🧾 Typical Logic Flow

1. Search for installed products matching `$ProductName`

   * Registry: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*`
   * 64-bit and 32-bit nodes scanned
   * Optional Win32_Product (WMI) fallback
2. If found, extract the **uninstall command or MSI code**
3. Run the uninstall silently (e.g., `msiexec /x {GUID} /qn /norestart`)
4. Wait for completion and capture exit code
5. Write success/failure logs

---

## 📊 Exit Codes

| Code | Meaning                                              |
| ---- | ---------------------------------------------------- |
| 0    | Success — software not found or successfully removed |
| 1    | Uninstall failed or returned non-zero code           |
| 2    | Invalid parameters                                   |
| 3    | Insufficient permissions                             |
| 4    | Unknown error                                        |

---

## 🧱 Intune Integration

Use this script as a **Remediation Script** or **Win32 app uninstall command**.

**Detection Script:**
Check if Adobe PDF (or any target software) exists.
**Remediation Script:**
Use this uninstall script.
Intune interprets `exit 0` as success / compliant.

---

## 🗃 Logging

* Default log location:

  ```
  C:\ProgramData\SoftwareRemoval\Logs\Uninstall-AdobePDF.log
  ```
* Each run appends a timestamped entry.
* Logs can be redirected via script parameter (if implemented).

---

## 🧩 Adaptation Tips

* To reuse for other products, modify:

  * Default `$ProductName`
  * Any hardcoded uninstall strings
  * Logging directory name
* Always test uninstalls in isolation before wide deployment.
* Keep uninstall switches silent (`/qn /norestart`) for managed automation.

---

## 🧰 Related References

* [Detect and uninstall Win32 apps via Intune](https://learn.microsoft.com/mem/intune/apps/apps-win32-app-management)
* [Uninstalling software with PowerShell](https://learn.microsoft.com/powershell/scripting/samples/sample-uninstalling-software)
* [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer)

---

## 🪪 License

MIT License © 2025 Tyler Gates
Provided *as-is*, without warranty or affiliation with Microsoft.

```
📁 `KofaxDetection/README.md`?
```
