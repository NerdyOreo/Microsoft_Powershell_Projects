# Sanitize-Scripts.ps1

A **PowerShell utility** that scans your `.ps1` scripts for sensitive or organization-specific data and creates **sanitized copies** for safe sharing or publishing.

> 🧩 This script was designed to make open-sourcing internal PowerShell projects safe — without altering your original files.

---

## 📋 Overview

`Sanitize-Scripts.ps1` reads one or more `.ps1` files, detects potential **secrets**, **tokens**, **emails**, **domain names**, and **organization identifiers**, and replaces them with generic placeholders.  
It then writes sanitized copies and generates mapping files that show what was replaced.

Nothing in your originals is changed — it always writes copies to a new folder.

---

## 🚀 Features

- Detects and replaces:
  - Emails, UPNs, domain\username formats  
  - IP addresses, MAC addresses, GUIDs, URLs, UNC paths  
  - Azure IDs (tenant, subscription, client, resource)  
  - JWT/Bearer tokens, SAS parameters, base64 blobs  
  - Certificates, keys, connection strings, secrets  
  - Company names (customizable pattern list)
- Outputs:
  - Sanitized `.ps1` copy  
  - `.mapping.json` and `.mapping.csv` files showing replacements  
- Supports:
  - Single files or recursive folder processing  
  - Domain whitelisting (e.g., keep `microsoft.com`, `github.com`)  
  - `-WhatIf` mode for dry runs (no writes)
- Creates a clean **summary table** at the end of execution.

---

## ⚙️ Requirements

| Requirement | Description |
|--------------|-------------|
| **PowerShell** | 7.x or Windows PowerShell 5.1 |
| **Execution Policy** | `RemoteSigned` or `Bypass` |
| **Permissions** | Read/write access to source/output directories |
| **No internet** | Works fully offline (no external API calls) |

---

## 🧠 Parameters

| Parameter | Description |
|------------|-------------|
| `-Files` | One or more `.ps1` files to sanitize |
| `-Path` | Folder path containing scripts |
| `-Recurse` | Process all subfolders |
| `-OutputDir` | Directory for sanitized copies (required) |
| `-DomainWhitelist` | Domains that should not be replaced (e.g., `github.com`, `microsoft.com`) |
| `-CompanyNamePatterns` | Company-specific words or patterns to replace |
| `-WhatIf` | Run in dry-run mode (no files written) |

---

## 💻 Usage Examples

### Sanitize Specific Files
```powershell
.\Sanitize-Scripts.ps1 -Files @(
  "C:\Scripts\Get-IntuneUserDeviceReport.ps1",
  "C:\Scripts\Uninstall-AdobePDF.ps1"
) -OutputDir "C:\Scripts\Sanitized_PS1"
````

### Sanitize an Entire Folder

```powershell
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -OutputDir "C:\Scripts\Sanitized_PS1"
```

### Dry Run (Preview Only)

```powershell
.\Sanitize-Scripts.ps1 -Path "C:\Scripts" -Recurse -WhatIf -OutputDir "C:\Scripts\Sanitized_PS1"
```

---

## 📦 Output Example

For `Get-IntuneUserDeviceReport.ps1`, you’ll get:

```
C:\Scripts\Sanitized_PS1\
│
├── Get-IntuneUserDeviceReport.sanitized.ps1
├── Get-IntuneUserDeviceReport.mapping.json
└── Get-IntuneUserDeviceReport.mapping.csv
```

The mapping files show the original → placeholder pairs (never containing actual data).

---

## 🧩 Customization

Edit the top section of the script to adjust:

* **CompanyNamePatterns** — list of phrases or domains unique to your organization.
* **DomainWhitelist** — public domains that should be preserved.
* **Patterns** — regular expressions for additional sanitization rules.

---

## 🧱 Best Practices

* Always review sanitized output before publishing.
* Test with `-WhatIf` first to confirm detection coverage.
* Add your own regex patterns for environment-specific replacements.
* Keep a secure backup of originals; sanitized copies are irreversible.
* Run through `PSScriptAnalyzer` after sanitizing for style consistency.

---

## 🧰 Related Tools

* [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer) – static code quality checks
* [GitHub Secret Scanning](https://docs.github.com/code-security/secret-scanning) – verify no secrets remain
* [Regex101.com](https://regex101.com) – test and refine your custom regex patterns

---

## 🪪 License

MIT License © 2025 Tyler Gates
Provided *as-is*, with no warranty or affiliation with Microsoft.

```
