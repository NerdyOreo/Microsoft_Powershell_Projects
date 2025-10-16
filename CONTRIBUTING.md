👋 Welcome!  
Thank you for your interest in improving or contributing to this collection of PowerShell scripts.  
These guidelines explain how to safely collaborate, maintain quality, and protect private information.

---

## 🧩 Project Overview

This repository contains sanitized and reusable PowerShell scripts focused on:
- Microsoft Intune
- Entra ID / Azure AD
- Microsoft Graph API
- Windows device management
- General automation and remediation patterns

All scripts here are **sanitized templates** — no company-specific or personally identifiable data should ever be included.

---

## ⚙️ How to Contribute

### Option 1 — Edit directly on GitHub
1. Navigate to the file you want to improve.
2. Click **✏️ Edit this file**.
3. Make your change.
4. Add a short, clear commit message.
5. Choose **Create a new branch for this commit** and open a **Pull Request (PR)**.

### Option 2 — Fork and work locally
If you prefer to work offline:
1. Fork this repository to your own GitHub account.
2. Clone your fork locally.
3. Make your edits and commit.
4. Push to your fork.
5. Open a Pull Request back to this repository.

---

## 🧪 Quality & Testing

Before committing or submitting a PR, please:

1. **Run [PSScriptAnalyzer](https://www.powershellgallery.com/packages/PSScriptAnalyzer)**  
   ```powershell
   Install-Module PSScriptAnalyzer -Scope CurrentUser
   Invoke-ScriptAnalyzer -Path . -Recurse -Settings Default
````

2. **Test in a safe environment**

   * Use test tenants, VMs, or demo data.
   * Never test against production systems with unvalidated changes.

3. **Validate syntax**

   ```powershell
   pwsh -NoProfile -Command { Test-ModuleManifest .\SomeScript.psd1 }
   ```

   *(if applicable)*

---

## 🧹 Sanitization & Privacy

> 🔒 **Absolutely no private or organizational data should ever appear in this repository.**

Before committing or pushing:

* Run `Sanitize-Scripts.ps1` on any `.ps1` files that originated from internal environments.
* Verify the output mapping (`.mapping.json` / `.mapping.csv`) to confirm that sensitive strings were replaced.
* Ensure no credentials, domains, or internal file paths remain.
* Do not include real device names, IPs, or user identifiers.

If you accidentally commit sensitive data, contact the maintainer immediately to purge the commit history.

---

## 🧱 Code Style

* Use **4 spaces** for indentation.
* Use **PascalCase** for functions, **camelCase** for variables.
* Always include **comment-based help**:

  ```powershell
  <#
  .SYNOPSIS
    Short description.
  .DESCRIPTION
    Longer explanation.
  .PARAMETER Example
    Description of parameter.
  .EXAMPLE
    Example usage.
  #>
  ```
* Use **CmdletBinding()** and `Param()` blocks for advanced functions.
* Include `-WhatIf` and `-Confirm:$false` support when applicable.
* Avoid hard-coding paths, credentials, or tenant identifiers.
* Keep scripts **idempotent** — running them twice shouldn’t break things.

---

## 🧾 Commit Messages

Use short, clear commit messages written in the **imperative mood**, e.g.:

```
Add logging to Intune rollout script
Fix regex for email sanitization
Update README with new folder structure
```

If your change is large, explain *why* in the extended description field.

---

## 🧰 Pull Request Guidelines

1. Create a separate branch for each change.
2. Keep PRs focused — one feature or fix per request.
3. Include before/after notes or screenshots if applicable.
4. Ensure all scripts run without syntax errors (`pwsh -NoProfile -File <script>`).
5. The maintainer will review for:

   * Security (no secrets or identifiers)
   * Readability and PowerShell best practices
   * Proper documentation and examples

---

## 🪪 Licensing

All contributions are released under the [MIT License](LICENSE).
By submitting a PR, you agree that your changes may be incorporated under that same license.

---

## 🙌 Thank You

Every contribution — from fixing typos to adding new modules — helps improve this project.
Your attention to security, consistency, and quality keeps this repository valuable to the PowerShell community.
