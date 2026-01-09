# ================================
# Master Removal Script
# ================================

# region Logging
$LogRoot = "C:\ProgramData\RemovalLogs"
New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path "$LogRoot\MasterRemoval.log" -Value "$timestamp $Message"
}

Write-Log "Master removal script starting"
# endregion


# -------------------
# Remove APPX
# -------------------
$appxList = @(
    "Microsoft.XboxApp",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MixedReality.Portal"
)

foreach ($selector in $appxList) {
    try {
        Write-Log "Removing Appx ${selector}"
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -like "*$selector*"} | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Write-Log "Success Appx ${selector}"
    }
    catch {
        Write-Log "Failed Appx removal ${selector}: $($_.Exception.Message)"
    }
}


# -------------------
# Remove Windows Capabilities
# -------------------
$capabilities = @(
    "App.Support.QuickAssist",
    "MathRecognize",
    "Microsoft.Windows.WordPad",
    "Print.Fax.Scan",
    "XPS.Viewer"
)

foreach ($selector in $capabilities) {
    try {
        Write-Log "Removing capability ${selector}"
        Remove-WindowsCapability -Online -Name $selector -ErrorAction Stop
        Write-Log "Success capability ${selector}"
    }
    catch {
        Write-Log "Failed capability removal ${selector}: $($_.Exception.Message)"
    }
}


# -------------------
# Remove Optional Features
# -------------------
$features = @(
    "WorkFolders-Client",
    "Printing-PrintToPDFServices-Features",
    "Xps-Foundation-Xps-Viewer",
    "MicrosoftWindowsPowerShellV2"
)

foreach ($selector in $features) {
    try {
        Write-Log "Disabling optional feature ${selector}"
        Disable-WindowsOptionalFeature -Online -FeatureName $selector -NoRestart -ErrorAction Stop
        Write-Log "Success feature ${selector}"
    }
    catch {
        Write-Log "Failed optional feature removal ${selector}: $($_.Exception.Message)"
    }
}


# -------------------
# Disable Bing Search / Web Results in Start Menu
# -------------------

Write-Log "Starting Bing Search removal"

try {
    $SearchKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (!(Test-Path $SearchKey)) {
        New-Item -Path $SearchKey -Force | Out-Null
    }

    New-ItemProperty -Path $SearchKey -Name "DisableSearchBoxSuggestions" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $SearchKey -Name "ConnectedSearchUseWeb" -Value 1 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $SearchKey -Name "ConnectedSearchUseWebOverMeteredConnections" -Value 0 -PropertyType DWord -Force | Out-Null
    New-ItemProperty -Path $SearchKey -Name "ConnectedSearchPrivacy" -Value 3 -PropertyType DWord -Force | Out-Null

    Write-Log "Bing Web Search successfully disabled"
}
catch {
    Write-Log "Failed to disable Bing search: $($_.Exception.Message)"
}


Write-Log "Master removal script complete"
