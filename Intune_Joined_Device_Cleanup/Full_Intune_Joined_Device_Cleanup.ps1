# =====================================================================
# Intune_Joined_Device_Cleanup.ps1
# Bing web search disable for all users without HKU provider errors
# =====================================================================

$LogPath = "C:\ProgramData\Intune_Joined_Device_Cleanup.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "$timestamp`t$Message"
}

Write-Log "----- Script start -----"

# ---------------------------------------------------------------------
# Disable Bing Search for default user profile (.DEFAULT affects new users)
# ---------------------------------------------------------------------

try {
    Write-Log "Configuring .DEFAULT user hive search settings"

    reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f
    reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f
    reg add "HKU\.DEFAULT\Software\Microsoft\Windows\CurrentVersion\Search" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

    Write-Log ".DEFAULT hive configured successfully"
}
catch {
    Write-Log ("Failed configuring .DEFAULT hive Error: " + $_.Exception.Message)
}

# ---------------------------------------------------------------------
# Apply setting to all currently loaded user hives under HKEY_USERS
# ---------------------------------------------------------------------

Write-Log "Enumerating mounted user hives"

$UserHives = reg query HKU 2>$null

foreach ($line in $UserHives) {

    if ($line -match "^HKEY_USERS\\") {

        $Hive = $line.Trim()

        # Skip system accounts
        if ($Hive -like "HKEY_USERS\S-1-5-18*" -or
            $Hive -like "HKEY_USERS\S-1-5-19*" -or
            $Hive -like "HKEY_USERS\S-1-5-20*") {

            Write-Log ("Skipping system hive " + $Hive)
            continue
        }

        Write-Log ("Configuring hive " + $Hive)

        try {
            reg add "$Hive\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f
            reg add "$Hive\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f
            reg add "$Hive\Software\Microsoft\Windows\CurrentVersion\Search" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f

            Write-Log ("Successfully configured hive " + $Hive)
        }
        catch {
            Write-Log ("Failed configuring hive " + $Hive + " Error: " + $_.Exception.Message)
        }
    }
}

Write-Log "----- Script complete -----"
