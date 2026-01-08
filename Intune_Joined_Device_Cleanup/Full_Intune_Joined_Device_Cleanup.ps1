<#
.SYNOPSIS
Cleans up built-in Windows bloat and disables Bing search for all users on Intune-managed devices.

.DESCRIPTION
- Removes selected Appx provisioned packages for all users.
- Removes selected Windows capabilities.
- Removes optional Windows features.
- Disables Bing search in Start Menu and Search Box via HKLM and all user HKCU hives.
- Writes logs to C:\Windows\Setup\Scripts\IntuneCleanup.log

.NOTES
Designed to run in system context via Intune.
#>

# --- Ensure script folder exists ---
$scriptFolder = "C:\Windows\Setup\Scripts"
if (-not (Test-Path $scriptFolder)) { New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null }

# --- Log file ---
$logfile = "$scriptFolder\IntuneCleanup.log"
"Starting Intune_Joined_Device_Cleanup.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append

# --------------------------
# Disable Bing search via HKLM
# --------------------------
$regPathLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $regPathLM)) { New-Item -Path $regPathLM -Force | Out-Null }

try {
    Set-ItemProperty -Path $regPathLM -Name "DisableSearchBoxSuggestions" -Value 1 -Force
    "Bing search disabled via HKLM successfully." | Out-File -FilePath $logfile -Append
} catch {
    $err = $_.ToString()
    "Failed to disable Bing search via HKLM. Error: $err" | Out-File -FilePath $logfile -Append
}

# --------------------------
# Disable Bing search for all existing user HKCU hives safely
# --------------------------
$usersFolder = "C:\Users"
foreach ($user in Get-ChildItem $usersFolder -Directory) {
    if ($user.Name -in @("Public","Default","Default User","All Users")) { continue }

    $ntUserDat = "$($user.FullName)\NTUSER.DAT"
    if (Test-Path $ntUserDat) {
        $hiveName = "TempHive_$($user.Name)"
        try {
            # Load the user hive
            reg.exe load "HKU\$hiveName" $ntUserDat | Out-Null

            # Use reg.exe to create key and set values
            $searchKey = "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Search"
            reg.exe add "$searchKey" /v BingSearchEnabled /t REG_DWORD /d 0 /f | Out-Null
            reg.exe add "$searchKey" /v CortanaConsent /t REG_DWORD /d 0 /f | Out-Null

            "Bing search disabled for user $($user.Name) successfully." | Out-File -FilePath $logfile -Append
        } catch {
            $err = $_.ToString()
            "Failed to disable Bing search for user $($user.Name). Error: $err" | Out-File -FilePath $logfile -Append
        } finally {
            # Unload the hive
            reg.exe unload "HKU\$hiveName" | Out-Null
        }
    }
}

# --------------------------
# Remove Appx packages
# --------------------------
$appxSelectors = @(
    'Microsoft.Microsoft3DViewer',
    'Microsoft.BingSearch',
    'Microsoft.549981C3F5F10',
    'MicrosoftCorporationII.MicrosoftFamily',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.Edge.GameAssist',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.WindowsMaps',
    'Microsoft.MixedReality.Portal',
    'Microsoft.BingNews',
    'Microsoft.MSPaint',
    'MicrosoftCorporationII.QuickAssist',
    'Microsoft.SkypeApp',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MicrosoftStickyNotes',
    'Microsoft.Wallet',
    'Microsoft.BingWeather',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.GamingApp',
    'Microsoft.YourPhone',
    'Microsoft.ZuneVideo'
)

try {
    $installedPackages = Get-AppxProvisionedPackage -Online
    foreach ($selector in $appxSelectors) {
        $found = $installedPackages | Where-Object { $_.DisplayName -eq $selector }
        if ($found) {
            try {
                $found | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction Stop
                "$selector removed successfully." | Out-File -FilePath $logfile -Append
            } catch {
                $err = $_.ToString()
                "Failed to remove $selector. Error: $err" | Out-File -FilePath $logfile -Append
            }
        } else {
            "$selector not installed." | Out-File -FilePath $logfile -Append
        }
    }
} catch {
    $err = $_.ToString()
    "Error enumerating Appx packages. Error: $err" | Out-File -FilePath $logfile -Append
}

# --------------------------
# Remove Windows capabilities
# --------------------------
$capabilitySelectors = @(
    'Browser.InternetExplorer',
    'MathRecognizer',
    'App.Support.QuickAssist',
    'App.StepsRecorder'
)

try {
    $installedCaps = Get-WindowsCapability -Online | Where-Object { $_.State -notin @('NotPresent','Removed') }
    foreach ($selector in $capabilitySelectors) {
        $found = $installedCaps | Where-Object { ($_.Name -split '~')[0] -eq $selector }
        if ($found) {
            try {
                $found | Remove-WindowsCapability -Online -ErrorAction Stop
                "$selector capability removed successfully." | Out-File -FilePath $logfile -Append
            } catch {
                $err = $_.ToString()
                "Failed to remove $selector capability. Error: $err" | Out-File -FilePath $logfile -Append
            }
        } else {
            "$selector capability not installed." | Out-File -FilePath $logfile -Append
        }
    }
} catch {
    $err = $_.ToString()
    "Error enumerating capabilities. Error: $err" | Out-File -FilePath $logfile -Append
}

# --------------------------
# Remove optional Windows features
# --------------------------
$featureSelectors = @(
    'Recall'
)

try {
    $installedFeatures = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -notin @('Disabled','DisabledWithPayloadRemoved') }
    foreach ($selector in $featureSelectors) {
        $found = $installedFeatures | Where-Object { $_.FeatureName -eq $selector }
        if ($found) {
            try {
                $found | Disable-WindowsOptionalFeature -Online -Remove -NoRestart -ErrorAction Stop
                "$selector feature removed successfully." | Out-File -FilePath $logfile -Append
            } catch {
                $err = $_.ToString()
                "Failed to remove $selector feature. Error: $err" | Out-File -FilePath $logfile -Append
            }
        } else {
            "$selector feature not installed." | Out-File -FilePath $logfile -Append
        }
    }
} catch {
    $err = $_.ToString()
    "Error enumerating features. Error: $err" | Out-File -FilePath $logfile -Append
}

# --- Finished ---
"Finished Intune_Joined_Device_Cleanup.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append
