<#
File: uninstall-adobe-pdf.ps1
Purpose:
  1) Ensure Kofax Power PDF is installed and (best-effort) set as default .pdf app
  2) If Kofax is default (or becomes default), silently uninstall any Adobe Acrobat/Reader (32/64-bit)

Notes:
  - Per-user default app (HKCU:\...UserChoice) is protected by a hash. This script uses DISM Import-DefaultAppAssociations
    to set the device default based on the detected Kofax ProgID, then verifies the current user's default where possible.
  - If Kofax is not default after the attempt, the script skips uninstall to avoid disrupting users.
  - For guaranteed results, deploy an Intune "Default App Associations" policy using the same ProgID.

Run As: System (Intune -> Devices -> Windows -> Scripts), 64-bit host
Exit codes:
  0    = Success or intentionally skipped (safety checks)
  2    = Nothing found to uninstall
  1618 = Another installer in progress
Logging: %ProgramData%\<DOMAIN>\<USERNAME>\<DOMAIN>0
#>

# ===========================
# region Prep and logging
# ===========================
$ErrorActionPreference = 'Stop'
$logRoot = Join-Path $env:ProgramData '<DOMAIN>\<USERNAME>'
New-Item -Path $logRoot -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = Join-Path $logRoot "AdobeUninstall-$<DOMAIN>1"

function Write-Log {
    param([string]$Message,[string]$Level='INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'u'), $Level, $Message
    Add-Content -Path $log -Value $line
}
Write-Log "Starting Kofax-default + Adobe uninstall workflow."

# Guard against concurrent installs
try {
    $inProgressKey = 'HKLM:\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>'
    if (Test-Path $inProgressKey) {
        $kids = Get-ChildItem $inProgressKey -ErrorAction SilentlyContinue
        if ($<DOMAIN>2 -gt 0) {
            Write-Log "Another installer is in progress. Exiting with 1618." 'WARN'
            exit 1618
        }
    }
} catch { Write-Log "MSI InProgress check warning: $($_.<DOMAIN>3)" 'WARN' }

# ===========================
# region Detect Kofax installation
# ===========================
Write-Log "Checking for Kofax/Nuance Power PDF installation..."
$kofaxFound = $false
$searchPaths = @(
    'HKLM:\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\Uninstall',
    'HKLM:\<DOMAIN>\<USERNAME>\Microsoft\<DOMAIN>\<USERNAME>\Uninstall'
)
foreach ($path in $searchPaths) {
    if (-not (Test-Path $path)) { continue }
    foreach ($sub in Get-ChildItem $path -ErrorAction SilentlyContinue) {
        try {
            $props = Get-ItemProperty $<DOMAIN>4 -ErrorAction SilentlyContinue
            $name  = $<DOMAIN>5
            if ([string]::IsNullOrWhiteSpace($name)) { continue }
            if ($name -match '<DOMAIN>\<USERNAME>+<DOMAIN>\<USERNAME>+PDF' -or $name -match '<DOMAIN>\<USERNAME>+PDF' -or $name -match '<DOMAIN>\<USERNAME>+<DOMAIN>\<USERNAME>+PDF') {
                $kofaxFound = $true
                Write-Log "Detected Kofax product: $name"
                break
            }
        } catch { Write-Log "Uninstall key read warning: $($_.<DOMAIN>3)" 'WARN' }
    }
    if ($kofaxFound) { break }
}
if (-not $kofaxFound) {
    Write-Log "Kofax Power PDF not found. Skipping Adobe uninstall to preserve PDF capability." 'WARN'
    exit 0
}

# ===========================
# region Discover Kofax ProgID for .pdf
# ===========================
Write-Log "Discovering Kofax ProgID for .pdf association..."
function Get-KofaxProgId {
    # Look for likely ProgIDs registered by Kofax/Nuance
    $candidates = @()
    foreach ($root in @('HKLM:\<DOMAIN>\<USERNAME>','HKCR:\')) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem $root -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -match '\\(Kofax|Nuance)\.PowerPDF'
        } | ForEach-Object {
            $candidates += $_.PSChildName
        }
    }
    $candidates = $candidates | Sort-Object -Unique

    # Prefer newest-looking version suffixes
    $preferred = $candidates | Sort-Object {
        if ($_ -match '\.(\d+)$') { [int]$matches[1] } else { 0 }
    } -Descending

    foreach ($pid in $preferred) {
        # Sanity check: must exist under HKLM:\<DOMAIN>\<USERNAME>\<ProgID>
        $clsPath = "HKLM:\<DOMAIN>\<USERNAME>\$pid"
        if (Test-Path $clsPath) {
            return $pid
        }
    }

    # Fallback guesses (commonly seen)
    $fallbacks = @(
        '<DOMAIN>6.5','<DOMAIN>7.5',
        '<DOMAIN>6.4','<DOMAIN>7.4',
        '<DOMAIN>8.3','<DOMAIN>9.3'
    )
    foreach ($f in $fallbacks) {
        if (Test-Path "HKLM:\<DOMAIN>\<USERNAME>\$f") { return $f }
    }
    return $null
}

$progId = Get-KofaxProgId
if ($null -eq $progId -or $progId -eq '') {
    Write-Log "Unable to determine a Kofax ProgID. Skipping changes." 'WARN'
    exit 0
}
Write-Log "Candidate Kofax ProgID: $progId"

# ===========================
# region Check & set default .pdf via DISM (device default)
# ===========================
function Get-UserPdfProgId {
    try {
        $key = "HKCU:\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\.<DOMAIN>\<USERNAME>"
        if (Test-Path $key) {
            return (Get-ItemProperty $key -ErrorAction SilentlyContinue).ProgId
        }
    } catch {}
    return $null
}

$beforeProgId = Get-UserPdfProgId
Write-Log "Current user .pdf ProgID: $beforeProgId"

$kofaxIsDefault = $false
if ($beforeProgId -and ($beforeProgId -match 'Kofax' -or $beforeProgId -match 'Nuance' -or $beforeProgId -eq $progId)) {
    $kofaxIsDefault = $true
    Write-Log "Kofax already set as default .pdf handler for the current user."
} else {
    # Best-effort: set device default using DISM with a minimal XML mapping
    try {
        $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".pdf" ProgId="$progId" ApplicationName="Kofax Power PDF"/>
</DefaultAssociations>
"@
        $xmlPath = Join-Path $env:TEMP "default-pdf-kofax-$<DOMAIN>10"
        $xml | Out-File -FilePath $xmlPath -Encoding utf8 -Force
        Write-Log "Importing default app associations via DISM using $xmlPath"
        $dism = Start-Process -FilePath <DOMAIN>11 -ArgumentList "/Online","/Import-DefaultAppAssociations:$xmlPath" -PassThru -WindowStyle Hidden -Wait
        Write-Log "DISM exit code: $($<DOMAIN>12)"

        # Re-check current user's ProgID (may not change immediately due to per-user hash)
        Start-Sleep -Seconds 2
        $afterProgId = Get-UserPdfProgId
        Write-Log "Post-DISM user .pdf ProgID: $afterProgId"

        if ($afterProgId -and ($afterProgId -match 'Kofax' -or $afterProgId -match 'Nuance' -or $afterProgId -eq $progId)) {
            $kofaxIsDefault = $true
            Write-Log "Kofax confirmed as default after DISM import."
        } else {
            # Even if user's choice did not flip, device default is now set for new users
            Write-Log "Kofax not confirmed as current user's default. Keeping Adobe to avoid disruption." 'WARN'
        }
    } catch {
        Write-Log "DISM import failed: $($_.<DOMAIN>3)" 'WARN'
    }
}

if (-not $kofaxIsDefault) {
    Write-Log "Safety check failed: Kofax is not the user's default .pdf app. Skipping Adobe uninstall." 'WARN'
    exit 0
}

Write-Log "Proceeding: Kofax is default (confirmed)."

# ===========================
# region Utility functions
# ===========================
function Stop-AdobeProcesses {
    try {
        $procs = @('AcroRd32','Acrobat','AdobeCollabSync','AcroCEF','RdrCEF','AdobeARM','armsvc')
        foreach ($p in $procs) {
            Get-Process -Name $p -ErrorAction SilentlyContinue | ForEach-Object {
                Write-Log "Stopping process: $($_.Name) PID=$($_.Id)"
                try { $_ | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
        $svc = Get-Service -Name "AdobeARMservice" -ErrorAction SilentlyContinue
        if ($null -ne $svc -and $<DOMAIN>13 -ne 'Stopped') {
            Write-Log "Stopping service AdobeARMservice"
            Stop-Service -Name "AdobeARMservice" -Force -ErrorAction SilentlyContinue
        }
    } catch { Write-Log "Stop-AdobeProcesses error: $($_.<DOMAIN>3)" 'WARN' }
}

function Get-UninstallEntries {
    $paths = @(
        'HKLM:\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\Uninstall',
        'HKLM:\<DOMAIN>\<USERNAME>\Microsoft\<DOMAIN>\<USERNAME>\Uninstall'
    )
    $targets = @()
    foreach ($path in $paths) {
        if (-not (Test-Path $path)) { continue }
        Get-ChildItem $path -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
                $name  = $<DOMAIN>5
                if ([string]::IsNullOrWhiteSpace($name)) { return }
                if ($name -match '<DOMAIN>\<USERNAME>+<DOMAIN>\<USERNAME>+Reader' -or
                    $name -match '^<DOMAIN>\<USERNAME>+Reader' -or
                    $name -match '<DOMAIN>\<USERNAME>+Acrobat(?!\s*Reader)' -or
                    $name -match '^Acrobat(?!\s*Reader)') {
                    $targets += [pscustomobject]@{
                        KeyPath              = $_.PSPath
                        DisplayName          = $name
                        DisplayVersion       = $<DOMAIN>14
                        UninstallString      = $<DOMAIN>15
                        QuietUninstallString = $<DOMAIN>16
                    }
                }
            } catch { Write-Log "Uninstall entry read warning: $($_.<DOMAIN>3)" 'WARN' }
        }
    }
    return $targets
}

function Get-NormalizedCommand {
    param([string]$UninstallString,[string]$QuietUninstallString)
    $cmd = if (-not [string]::IsNullOrWhiteSpace($QuietUninstallString)) { $QuietUninstallString } else { $UninstallString }
    if ([string]::IsNullOrWhiteSpace($cmd)) { return $null }
    $trim = $<DOMAIN>17()

    if ($trim -match '^\{[0-9A-Fa-f\-]{36}\}$') { return "<DOMAIN>18 /x $trim /qn REBOOT=ReallySuppress" }

    if ($trim -match '(?i)msiexec(\.exe)?') {
        $normalized = $trim -replace '(?i)\s/([Ii])\s', ' /x '
        if ($normalized -notmatch '(?i)/x')  { $normalized = "$normalized /x" }
        if ($normalized -notmatch '(?i)/qn') { $normalized = "$normalized /qn" }
        if ($normalized -notmatch '(?i)REBOOT=') { $normalized = "$normalized REBOOT=ReallySuppress" }
        return $normalized
    }

    if ($trim -match '(?i)\.exe') {
        $normalized = $trim
        foreach ($flag in @('/sAll','/rs','/rps','/msi','/norestart','/quiet')) {
            if ($normalized -notmatch [regex]::Escape($flag)) { $normalized = "$normalized $flag" }
        }
        return $normalized
    }

    if ($trim -match '\{[0-9A-Fa-f\-]{36}\}') { return "<DOMAIN>18 /x $trim /qn REBOOT=ReallySuppress" }

    return $trim
}

function Invoke-CommandLine {
    param([string]$CommandLine)
    if ([string]::IsNullOrWhiteSpace($CommandLine)) { return 0 }
    Write-Log "Executing: $CommandLine"

    $exe = $CommandLine; $args = $null
    if ($<DOMAIN>19('"')) {
        $close = $<DOMAIN>20('"',1)
        $exe = $<DOMAIN>21(1, $close-1)
        $args = $<DOMAIN>21($close+1).Trim()
    } else {
        $parts = $<DOMAIN>22(' ',2)
        $exe = $parts[0]; $args = if ($<DOMAIN>23 -gt 1) { $parts[1] } else { '' }
    }

    $psi = New-Object <DOMAIN>24
    $<DOMAIN>25 = $exe; $<DOMAIN>26 = $args
    $<DOMAIN>27 = $false
    $<DOMAIN>28 = $true
    $<DOMAIN>29  = $true

    $p = New-Object <DOMAIN>30
    $<DOMAIN>31 = $psi
    $null = $<DOMAIN>32()
    $stdout = $<DOMAIN>33()
    $stderr = $<DOMAIN>34()
    $<DOMAIN>35()

    Write-Log "ExitCode=$($<DOMAIN>36)"
    if ($stdout) { Write-Log "STDOUT: $stdout" }
    if ($stderr) { Write-Log "STDERR: $stderr" 'WARN' }
    return $<DOMAIN>36
}

# ===========================
# region Uninstall Adobe
# ===========================
Write-Log "Stopping Adobe processes/services."
Stop-AdobeProcesses

$found = Get-UninstallEntries
if (-not $found -or $<DOMAIN>37 -eq 0) {
    Write-Log "No Adobe Acrobat/Reader products found. Exiting."
    exit 2
}

$overallSuccess = $true
foreach ($app in $found) {
    Write-Log "Found Adobe product: $($<DOMAIN>38) v$($<DOMAIN>39)"
    $cmd = Get-NormalizedCommand -UninstallString $<DOMAIN>40 -QuietUninstallString $<DOMAIN>41
    if (-not $cmd) {
        Write-Log "Missing uninstall string for $($<DOMAIN>38). Skipping." 'WARN'
        $overallSuccess = $false
        continue
    }
    $code = Invoke-CommandLine -CommandLine $cmd
    if ($code -in 0,1641,3010) { Write-Log "Uninstall success for $($<DOMAIN>38)." }
    else { Write-Log "Uninstall returned code $code for $($<DOMAIN>38)." 'WARN'; $overallSuccess = $false }
}

Stop-AdobeProcesses
$remaining = Get-UninstallEntries
if ($remaining -and $<DOMAIN>42 -gt 0) {
    Write-Log "Remaining Adobe entries after uninstall attempts:" 'WARN'
    $remaining | ForEach-Object { Write-Log "Still present: $($_.DisplayName) v$($_.DisplayVersion)" 'WARN' }
    $overallSuccess = $false
}

if ($overallSuccess) { Write-Log "All targeted Adobe PDF products removed successfully."; exit 0 }
else { Write-Log "Some Adobe products may remain or returned warnings. Review log: $log" 'WARN'; exit 0 }

