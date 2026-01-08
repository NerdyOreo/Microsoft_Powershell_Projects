# Intune_Joined_Device_Cleanup

A collection of PowerShell scripts designed to clean up and optimize Windows devices in an Intune-managed environment. These scripts are intended for devices joined to Azure AD or Hybrid AD and can be deployed via Intune to enforce consistent configuration and remove unnecessary components.

---

## Included Scripts

| Script | Purpose |
|--------|---------|
| `DisableBingSearch.ps1` | Disables Bing search integration and Cortana suggestions in the Start menu and Search box for a cleaner user experience. |
| `RemovePackages.ps1` | Removes selected built-in Windows Appx packages (e.g., 3D Viewer, Xbox, Skype, Edge GameAssist) for a leaner system. |
| `RemoveCapabilities.ps1` | Removes optional Windows capabilities such as Internet Explorer, Quick Assist, Math Recognizer, and Steps Recorder. |
| `RemoveFeatures.ps1` | Disables optional Windows features, e.g., Recall, to reduce footprint and unnecessary functionality. |

---

## Deployment

These scripts are designed for deployment via Microsoft Intune:

1. Save each script as a `.ps1` file.
2. In **Intune → Devices → PowerShell Scripts**, add a new script for each `.ps1` file.
3. Configure execution:
   - Run using logged-on credentials for `HKCU` modifications (required for `DisableBingSearch.ps1`).
   - Run 64-bit PowerShell.
   - Optional: disable signature enforcement unless scripts are signed.
4. Assign scripts to appropriate device or user groups.
5. Monitor execution status in Intune.

---

## Notes & Recommendations

- `DisableBingSearch.ps1` changes both machine-level and user-level registry keys. HKCU changes apply per user.
- The scripts perform **non-reversible removals** for packages, capabilities, and features. Test in a lab environment before production deployment.
- Logging is implemented in each script to `C:\Windows\Setup\Scripts\*.log` for troubleshooting.
- Intended for Windows 10 and 11 devices.

---

## Contribution

Contributions and suggestions are welcome. Please fork the repository and submit a pull request with improvements, fixes, or new scripts.

---

## License

This repository is released under the MIT License. See `LICENSE` for details.

