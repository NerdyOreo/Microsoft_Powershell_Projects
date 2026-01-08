<#
.SYNOPSIS
Enterprise cleanup for Intune-joined Windows devices.

.DESCRIPTION
- Disables Bing web search in Start
- Disables Cortana consent
- Applies settings for all current and future users
- Removes selected Appx provisioned packages
- Removes specified Windows capabilities
- Removes optional Windows features such as Recall
- Logs to C:\Windows\Setup\Scripts\IntuneCleanup.log

.NOTES
Designed to run in SYSTEM context via Intune Management Extension
Safe for repeated runs
#>

# --------------------------
# Logging
# --------------------------
$scriptFolder = "C:\Windows\Setup\Scripts"
if (-not (Test-Path $scriptFolder)) { New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null }

$logfile = "$scriptFolder\IntuneCleanup.log"
"===== Intune Cleanup Start $(Get-Date) =====" | Out-File -FilePath $logfile -Append

function Write-Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp  $msg" | Out-File -FilePath $logfile -Append
}

# --------------------------
# Disable Bing Search - HKLM Policy
# --------------------------
try {
    $regPathLM = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    if (-not (Test-Path $regPathLM)) { New-Item -Path $regPathLM -Force | Out-Null }

    Set-ItemProperty -Path $regPathLM -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
    Write-Log "Bing search disabled globally via HKLM policy"
} catch {
    Write-Log "Failed HKLM Bing disable: $($_.Exception.Message)"
}

# --------------------------
# Disable Bing Search for all existing user profiles (safe hive load)
# --------------------------
$usersFolder = "C:\Users"

foreach ($user in Get-ChildItem $usersFolder -Directory) {

    if ($user.Name -in @("Public","Default","Default User","All Users")) { continue }

    $ntUserDat = "$($user.FullName)\NTUSER.DAT"

    if (Test-Path $ntUserDat) {

        $hiveName = "TempHive_$($user.Name)"

        try {
            reg.exe load "HKU\$hiveName" "$ntUserDat" | Out-Null

            $searchKey = "HKU\$hiveName\Software\Microsoft\Windows\CurrentVersion\Search"

            reg.exe add "$searchKey" /f | Out-Null

            reg.exe add "$searchKey" /v BingSearchEnabled /t REG_DWORD /d 0 /f | Out-Null
            reg.exe add "$searchKey" /v CortanaConsent /t REG_DWORD /d 0 /f | Out-Null

            Write-Log "Bing search disabled for user profile $($user.Name)"
        } catch {
            Write-Log "Failed to modify hive for $($user.Name): $($_.Exception.Message)"
        } finally {
            reg.exe unload "HKU\$hiveName" | Out-Null
        }
    }
}

# --------------------------
# Remove Appx provisioned packages
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
                Write-Log "Removed Appx package $selector"
            } catch {
                Write-Log "Failed Appx removal $selector: $($_.Exception.Message)"
            }
        } else {
            Write-Log "Appx package not present: $selector"
        }
    }
} catch {
    Write-Log "Error enumerating Appx packages: $($_.Exception.Message)"
}

# --------------------------
# Remove Windows Capabilities
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
                Write-Log "Removed capability $selector"
            } catch {
                Write-Log "Failed capability removal $selector: $($_.Exception.Message)"
            }
        } else {
            Write-Log "Capability not present: $selector"
        }
    }
} catch {
    Write-Log "Error enumerating capabilities: $($_.Exception.Message)"
}

# --------------------------
# Remove optional Windows features such as Recall
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
                Write-Log "Removed optional feature $selector"
            } catch {
                Write-Log "Failed optional feature removal $selector: $($_.Exception.Message)"
            }
        } else {
            Write-Log "Optional feature not present: $selector"
        }
    }
} catch {
    Write-Log "Error enumerating optional features: $($_.Exception.Message)"
}

Write-Log "===== Intune Cleanup Completed $(Get-Date) ====="
