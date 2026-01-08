<#
.SYNOPSIS
Intune_Joined_Device_Cleanup.ps1
Removes built-in bloatware, disables Bing search, and applies enterprise cleanup to Windows 10/11 devices.
#>

$scriptFolder = "C:\Windows\Setup\Scripts"
New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
$logfile = "$scriptFolder\Cleanup.log"

"Starting Intune_Joined_Device_Cleanup at $(Get-Date)" | Out-File -FilePath $logfile -Append
"`r`n" | Out-File -FilePath $logfile -Append

# -----------------------------
# 1 Disable Bing Search
# -----------------------------
"Disabling Bing search and search suggestions..." | Out-File -FilePath $logfile -Append

try {
    # For all users via policy
    $regPath1 = "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer"
    New-Item -Path $regPath1 -Force | Out-Null
    Set-ItemProperty -Path $regPath1 -Name "DisableSearchBoxSuggestions" -Value 1 -Force

    # For current user
    $regPath2 = "HKCU\Software\Microsoft\Windows\CurrentVersion\Search"
    Set-ItemProperty -Path $regPath2 -Name "BingSearchEnabled" -Value 0 -Force
    Set-ItemProperty -Path $regPath2 -Name "CortanaConsent" -Value 0 -Force

    "Bing search disabled successfully." | Out-File -FilePath $logfile -Append
} catch {
    "Failed to disable Bing search: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
}

"`r`n" | Out-File -FilePath $logfile -Append

# -----------------------------
# 2 Remove Appx Packages
# -----------------------------
"Removing selected Appx packages for all users..." | Out-File -FilePath $logfile -Append

$packages = @(
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
    foreach ($pkg in $packages) {
        $found = $installedPackages | Where-Object { $_.DisplayName -eq $pkg }
        if ($found) {
            try {
                $found | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction Stop
                "$pkg removed successfully." | Out-File -FilePath $logfile -Append
            } catch {
                "$pkg removal failed: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
            }
        } else {
            "$pkg not installed." | Out-File -FilePath $logfile -Append
        }
    }
} catch {
    "Failed to enumerate Appx packages: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
}

"`r`n" | Out-File -FilePath $logfile -Append

# -----------------------------
# 3️ Remove Windows Capabilities
# -----------------------------
"Removing selected Windows capabilities..." | Out-File -FilePath $logfile -Append

$capabilities = @(
    'Browser.InternetExplorer',
    'MathRecognizer',
    'App.Support.QuickAssist',
    'App.StepsRecorder'
)
