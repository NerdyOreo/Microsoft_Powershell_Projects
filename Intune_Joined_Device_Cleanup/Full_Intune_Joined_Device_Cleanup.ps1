<#
.SYNOPSIS
Cleans up built-in Windows bloat and disables Bing search for all users on Intune-managed devices.

.DESCRIPTION
- Removes selected Appx provisioned packages for all users.
- Removes selected Windows capabilities.
- Removes optional Windows features.
- Disables Bing search in Start Menu and Search Box via HKLM and all existing HKCU hives.
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
# Disable Bing search for all existing user HKCU hives
# --------------------------
$usersFolder = "C:\Users"
foreach ($user in Get-ChildItem $usersFolder -Directory) {
    if ($user.Name -in @("Public","Default","Default User","All Users")) { continue }

    $ntUserDat = "$($user.FullName)\NTUSER.DAT"
    if (Test-Path $ntUserDat) {
        $hiveName = "TempHive_$($user.Name)"
        $loaded = $false

        try {
            # Attempt to load hive
            reg.exe load "HKU\$hiveName" $ntUserDat 2>$null
            if (Test-Path "HKU:\$hiveName") { $loaded = $true }

            if ($loaded) {
                $regPathCU = "HKU:\$hiveName\Software\Microsoft\Windows\CurrentVersion\Search"
                if (-not (Test-Path $regPathCU)) { New-Item -Path $regPathCU -Force | Out-Null }

                Set-ItemProperty -Path $regPathCU -Name "BingSearchEnabled" -Value 0 -Force
                Set-ItemProperty -Path $regPathCU -Name "CortanaConsent" -Value 0 -Force
                "Bing search disabled for user $($user.Name) successfully." | Out-File -FilePath $logfile -Append
            } else {
                "Skipping $($user.Name) hive; could not load (in use or locked)." | Out-File -FilePath $logfile -Append
            }
        } catch {
            $err = $_.ToString()
            "Failed to modify user $($user.Name) hive. Error: $err" | Out-File -FilePath $logfile -Append
        } finally {
            if ($loaded) { reg.exe unload "HKU\$hiveName" | Out-Null }
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
