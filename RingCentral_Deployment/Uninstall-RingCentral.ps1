# Attempts to uninstall RingCentral, supports MSI or EXE-based installs

$ErrorActionPreference = "SilentlyContinue"
$log = "$env:ProgramData\RingCentralUninstall.log"
Function Log { param([string]$m) ("{0} {1}" -f (Get-Date).ToString("s"), $m) | Out-File $log -Append -Encoding UTF8 }

try {
    Get-Process -Name "RingCentral" -ErrorAction SilentlyContinue | Stop-Process -Force
    # Try MSI uninstall (if present)
    $msi = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
           Where-Object { $_.DisplayName -like "*RingCentral*" } |
           Select-Object -First 1
    if ($msi -and $msi.PSObject.Properties.Name -contains "UninstallString") {
        $cmd = $msi.UninstallString.Replace("/I","/X") + " /qn /norestart"
        Log "Running MSI uninstall: $cmd"
        Start-Process "cmd.exe" -ArgumentList "/c $cmd" -Wait
    } else {
        # Try EXE uninstall if available
        $exe = "C:\Program Files\RingCentral\unins000.exe"
        if (Test-Path $exe) {
            Log "Running EXE uninstall: $exe /S"
            Start-Process $exe -ArgumentList "/S" -Wait
        }
    }
    Remove-Item "C:\Program Files\RingCentral" -Recurse -Force -ErrorAction SilentlyContinue
    Log "Uninstall finished."
    Exit 0
} catch {
    Log "Uninstall error: $_"
    Exit 1
}
