# Get-IntuneUserDeviceReport.ps1

Generates a detailed **user ↔ device report** from Microsoft Intune and Entra ID (formerly Azure AD) using Microsoft Graph.

> 🧩 This script is published as a sanitized template.  
> Replace any placeholders or example identifiers with your own tenant values before running.

---

## 📋 Overview

This script connects to the **Microsoft Graph API** and retrieves all managed devices and assigned users from Intune.  
It then correlates user information with device compliance, ownership, OS, and check-in data — producing a CSV report and optional on-screen summary.

---

## 🚀 Features

- Queries **Intune managed devices** and **user relationships**  
- Includes key metadata: OS, version, compliance, ownership, and last check-in  
- Supports **filtering** by platform or user  
- Outputs **CSV** and console table  
- Built-in **`-WhatIf`** support for dry runs  
- Modular and Intune-friendly — can be used as a reporting script in automation

---

## ⚙️ Requirements

| Requirement | Description |
|--------------|-------------|
| **PowerShell** | 7.x (recommended) or Windows PowerShell 5.1 |
| **Modules** | [Microsoft.Graph] or [Microsoft.Graph.Beta] |
| **Permissions (Scopes)** | `Device.Read.All`, `User.Read.All`, `Directory.Read.All` |
| **Network Access** | Must reach `graph.microsoft.com` endpoints |

Install the module if needed:

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
````

---

## 🧠 Parameters

| Parameter              | Type   | Description                                                      |
| ---------------------- | ------ | ---------------------------------------------------------------- |
| `OutputPath`           | String | Where to save the CSV report (default: `.\UserDeviceReport.csv`) |
| `FilterUPN`            | String | Optional — filter results for a specific user                    |
| `Platform`             | String | Optional — filter by OS (`Windows`, `iOS`, `Android`, `macOS`)   |
| `IncludeCompliantOnly` | Switch | Include only compliant devices                                   |
| `WhatIf`               | Switch | Simulate report generation without output                        |

---

## 💻 Usage

```powershell
# 1. Connect to Microsoft Graph interactively
Connect-MgGraph -Scopes "Device.Read.All","Directory.Read.All","User.Read.All"

# 2. Run the report
.\Get-IntuneUserDeviceReport.ps1 -OutputPath ".\examples\UserDeviceReport.csv"

# 3. (Optional) Filter by platform or user
.\Get-IntuneUserDeviceReport.ps1 -Platform Windows -FilterUPN "user@domain.com"
```

---

## 📊 Example Output Columns

| Column              | Description                         |
| ------------------- | ----------------------------------- |
| `UserPrincipalName` | The user's UPN (email-style name)   |
| `DisplayName`       | Friendly user name                  |
| `DeviceName`        | Managed device name                 |
| `OS` / `OSVersion`  | Operating system type and version   |
| `Ownership`         | Corporate or Personal               |
| `ComplianceState`   | Compliant, NonCompliant, or Unknown |
| `LastCheckIn`       | Last contact time with Intune       |
| `DeviceId`          | Unique device GUID                  |

---

## 🧩 Notes & Best Practices

* For large tenants, use paging or throttling with `Get-MgDeviceManagementManagedDevice`.
* To automate without interaction, register an **Azure App** and use certificate or secret auth.
* Clean any remaining tenant-specific strings before public publishing.
* Review output CSVs for any sensitive identifiers before sharing.

---

## 🧰 Related Tools

* **Sanitize-Scripts.ps1** — use to strip company or user data before uploading code publicly
* **PSScriptAnalyzer** — static analysis for style and quality
* **Intune Reporting via Graph** — [Microsoft Docs](https://learn.microsoft.com/graph/api/resources/intune-devices-manageddevice?view=graph-rest-1.0)

---

## 🪪 License

MIT License © 2025 Tyler Gates
Provided *as-is*, with no warranty or affiliation with Microsoft.

```
