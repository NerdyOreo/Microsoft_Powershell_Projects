# RemoveFeatures.ps1
# Disables and removes selected optional Windows features

$scriptFolder = "C:\Windows\Setup\Scripts"
New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
$logfile = "$scriptFolder\RemoveFeatures.log"

"Starting RemoveFeatures.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append

$selectors = @(
    'Recall'
)

$installed = Get-WindowsOptionalFeature -Online | Where-Object { $_.State -notin @('Disabled','DisabledWithPayloadRemoved') }

foreach ($selector in $selectors) {
    $found = $installed | Where-Object { $_.FeatureName -eq $selector }
    if ($found) {
        try {
            $found | Disable-WindowsOptionalFeature -Online -Remove -NoRestart -ErrorAction Stop
            "$selector removed successfully." | Out-File -FilePath $logfile -Append
        } catch {
            "$selector removal failed. Error: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
        }
    } else {
        "$selector not installed." | Out-File -FilePath $logfile -Append
    }
}

"Finished RemoveFeatures.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append
