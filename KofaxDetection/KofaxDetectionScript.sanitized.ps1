# detection-kofax.ps1
$minVersion = [version]'5.10.24208.0100'
$found = $false

$regPaths = @(
  "HKLM:\<DOMAIN>\<USERNAME>\<DOMAIN>\<USERNAME>\Uninstall\*",
  "HKLM:\<DOMAIN>\<USERNAME>\Microsoft\<DOMAIN>\<USERNAME>\Uninstall\*"
)

foreach ($p in $regPaths) {
    $apps = Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "Kofax Power PDF*"
    }
    foreach ($app in $apps) {
        try { $ver = [version]$<DOMAIN>0 } catch { $ver = $null }
        if ($ver -and $ver -ge $minVersion) { $found = $true; break }
    }
    if ($found) { break }
}

# fallback to exe check
if (-not $found) {
    $exeCandidates = @(
        "C:\Program <DOMAIN>\<USERNAME>\Power PDF <DOMAIN>\<USERNAME>\<DOMAIN>1",
        "C:\Program Files (x86)\<DOMAIN>\<USERNAME> PDF <DOMAIN>\<USERNAME>\<DOMAIN>1"
    )
    foreach ($f in $exeCandidates) {
        if (Test-Path $f) { $found = $true; break }
    }
}

if ($found) { Write-Output "Detected"; exit 0 } else { Write-Output "Not detected"; exit 1 }

