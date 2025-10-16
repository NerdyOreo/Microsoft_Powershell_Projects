# KofaxDetectionScript.ps1

An **Intune detection script template** for verifying whether a Kofax application (or any Windows app) is installed and healthy.

> 🧩 This script is published as a sanitized template.  
> Update the detection criteria (paths, registry keys, product codes, versions) to match your environment.

---

## 📋 Overview

This script runs a set of **read-only checks** to determine whether an app is present and meets minimum version/health requirements.  
It uses standard detection signals (file paths, registry keys, product GUIDs, running services) and exits with a code that Intune understands.

---

## 🚀 What It Checks (examples)

- **File/Folder presence**: e.g., `C:\Program Files\Kofax\App\bin\app.exe`  
- **Registry keys/values**: e.g., `HKLM:\Software\Vendor\Product`  
- **Product code / DisplayName** from Uninstall keys  
- **Version** of an EXE/DLL or registry value  
- **Service state** (optional): installed and running

> Customize these checks in the top “CONFIG” region of the script.

---

## ⚙️ Requirements

| Requirement | Description |
|------------|-------------|
| **PowerShell** | 7.x or Windows PowerShell 5.1 |
| **Permissions** | Standard user is usually enough (read-only checks) |
| **Execution Policy** | `RemoteSigned` or `Bypass` (for deployment) |

---

## 🧠 Parameters (typical)

| Parameter | Type | Description |
|----------|------|-------------|
| `RequiredVersion` | String | Minimum product version (e.g., `1.2.3`) |
| `InstallPath` | String | Override default expected install path |
| `LogPath` | String | Optional log file destination |
| `Verbose` | Switch | Extra console output for troubleshooting |

> Your script may expose fewer/more params depending on how you structure detection.

---

## 🧪 Exit Codes (Intune convention)

- **`0`** → **Detected / Installed** (meets all criteria)  
- **Non-zero** → **Not Detected** (missing or below required version)

Intune uses the exit code to decide whether remediation is needed.

---

## 💻 Usage

### In Intune (Detection Rule)
- Assign this script as a **custom detection** script for a Win32 app.
- Intune will treat **exit `0`** as *installed* and **non-zero** as *not installed*.

### Local testing
```powershell
# Example: require at least version 1.2.3
powershell -ExecutionPolicy Bypass -File .\KofaxDetectionScript.ps1 -RequiredVersion "1.2.3"
echo $LASTEXITCODE
````

---

## 🧩 Customization Tips

* **Paths**: Set default paths in the config region, then allow `-InstallPath` overrides.
* **Registry**: Check both 64-bit and 32-bit Uninstall hives for product entries.
* **Versioning**: Use `[version]` type comparisons (e.g., `[version]$found -ge [version]$required`).
* **Resilience**: Wrap each probe in `try/catch` and treat exceptions as “not detected.”
* **Speed**: Keep checks minimal — detection runs frequently on endpoints.
* **Noise**: Use `Write-Verbose` for details; keep default output clean.

---

## 🗃 Optional Logging

If you enable logging, a simple pattern is:

```
C:\ProgramData\AppDetection\Logs\KofaxDetection.log
```

Log only **high-level** results (found/missing, version). Avoid sensitive data.

---

## 🔄 Pairing with Remediation

* Use this detection script with an **Intune Remediation** or **Win32 app**.
* If detection fails (non-zero), the remediation script can **install or repair** the app, then detection runs again.

---

## 🧰 Related Tools

* `Sanitize-Scripts.ps1` — use this to scrub company data before publishing code
* `PSScriptAnalyzer` — static analysis for style and best practices

---

## 🪪 License

MIT License © 2025 Tyler Gates
Provided *as-is*, without warranty or affiliation with Microsoft.

```
