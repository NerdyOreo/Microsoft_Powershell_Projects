# =====================================================================
# Intune_Joined_Device_Cleanup.ps1
# Safely disables Bing web search and removes unwanted components
# SYSTEM compatible and user-hive safe
# =====================================================================

$LogPath = "C:\ProgramData\Intune_Joined_Device_Cleanup.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "$timestamp`t$Message"
}

Write-Log "----- Script start -----"

# =====================================================================
# Section 1: Disable Bing Search for all users
# =====================================================================

function Disable-BingSearchForHive {
    param([string]$HiveRoot)

    try {
        $regPath = "$HiveRoot\Software\Microsoft\Windows\CurrentVersion\Search"

        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
            Write-Log ("Created registry path " + $regPath)
        }

        New-ItemProperty -Path $regPath -Name "BingSearchEnabled" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "CortanaConsent" -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $regPath -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null

        Write-Log ("Disabled Bing search for hive root " + $HiveRoot)
    }
    catch {
        Write-Log ("Failed setting values for hive " + $HiveRoot + " Error: " + $_.Exception.Message)
    }
}

# Apply to Default User (future profiles)
Disable-BingSearchForHive -HiveRoot "HKU\.DEFAULT"

# Apply to each mounted user hive
Get-ChildItem Registry::HKEY_USERS | ForEach-Object {
    Disable-BingSearchForHive -HiveRoot $_.Name
}

# =====================================================================
# Section 2: Remove Appx packages for all users
# =====================================================================

$AppxToRemove = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MSPaint",
    "Microsoft.People",
    "Microsoft.SkypeApp",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.XboxApp",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.Xbox.TCUI"
)

foreach ($selector in $AppxToRemove) {
    try {
        Get-AppxPackage -AllUsers -Name $selector | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Write-Log ("Removed Appx package " + $selector)
    }
    catch {
        Write-Log ("Failed Appx removal " + $selector + " Error: " + $_.Exception.Message)
    }
}

# =====================================================================
# Section 3: Remove Capabilities
# =====================================================================

$CapabilitiesToRemove = @(
    "App.Support.QuickAssist*",
    "Microsoft.Windows.Notepad*",
    "Microsoft.Windows.WordPad*"
)

foreach ($selector in $CapabilitiesToRemove) {
    try {
        Get-WindowsCapability -Online | Where-Object Name -Like $selector | Remove-WindowsCapability -Online -ErrorAction Stop
        Write-Log ("Removed capability " + $selector)
    }
    catch {
        Write-Log ("Failed capability removal " + $selector + " Error: " + $_.Exception.Message)
    }
}

# =====================================================================
# Section 4: Remove Optional Features
# =====================================================================

$FeaturesToRemove = @(
    "WorkFolders-Client",
    "Printing-XPSServices-Features",
    "WindowsMediaPlayer"
)

foreach ($selector in $FeaturesToRemove) {
    try {
        Disable-WindowsOptionalFeature -FeatureName $selector -Online -NoRestart -ErrorAction Stop
        Write-Log ("Disabled optional feature " + $selector)
    }
    catch {
        Write-Log ("Failed optional feature removal " + $selector + " Error: " + $_.Exception.Message)
    }
}

Write-Log "----- Script complete -----"
