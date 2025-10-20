# RingCentral — Intune Deployment

## Summary
Installs the latest RingCentral for Windows silently via Intune using a PowerShell script that downloads from RingCentral CDN.

## Intune Settings
- Devices → Scripts → Add → Windows 10 and later
- Upload: `Install-RingCentral.ps1`
- Run with logged-on credentials: **No**
- Enforce signature check: **No**
- Run in 64-bit PowerShell: **Yes**
- Assign: **All Devices** (or pilot group first)

## Validation
- Folder present: `C:\Program Files\RingCentral`
- Log: `C:\ProgramData\RingCentralInstall.log`
