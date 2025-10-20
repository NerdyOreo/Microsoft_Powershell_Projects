# RingCentral Silent Install Script for Intune
# Runs under system context, downloads and installs latest stable build

$ErrorActionPreference = "Stop"
$DownloadUrl = "https://downloads.ringcentral.com/desktop/rc/production/windows/RingCentral.exe"
$InstallerPath = "$env:ProgramData\RingCentralInstaller.exe"
$LogPath = "$env:ProgramData\RingCentralInstall.log"

Write-Output "Starting RingCentral deployment..." | Out-File $LogPath -Encoding UTF8

try {
    # Download the installer
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing
    Write-Output "Downloaded RingCentral installer to $InstallerPath" | Out-File $LogPath -Append -Encoding UTF8

    # Run the silent install
    Start-Process -FilePath $InstallerPath -ArgumentList "/S" -Wait
    Write-Output "RingCentral installed successfully." | Out-File $LogPath -Append -Encoding UTF8
}
catch {
    Write-Output "RingCentral installation failed: $_" | Out-File $LogPath -Append -Encoding UTF8
    Exit 1
}

# Verify install
$AppPath = "C:\Program Files\RingCentral"
if (Test-Path $AppPath) {
    Write-Output "Validation passed. RingCentral installed at $AppPath" | Out-File $LogPath -Append -Encoding UTF8
    Exit 0
} else {
    Write-Output "Validation failed. RingCentral directory not found." | Out-File $LogPath -Append -Encoding UTF8
    Exit 1
}
