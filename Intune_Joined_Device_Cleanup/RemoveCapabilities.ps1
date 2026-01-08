# RemoveCapabilities.ps1
# Removes selected Windows capabilities

$scriptFolder = "C:\Windows\Setup\Scripts"
New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
$logfile = "$scriptFolder\RemoveCapabilities.log"

"Starting RemoveCapabilities.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append

$selectors = @(
    'Browser.InternetExplorer',
    'MathRecognizer',
    'App.Support.QuickAssist',
    'App.StepsRecorder'
)

$installed = Get-WindowsCapability -Online | Where-Object { $_.State -notin @('NotPresent','Removed') }

foreach ($selector in $selectors) {
    $found = $installed | Where-Object { ($_.Name -split '~')[0] -eq $selector }
    if ($found) {
        try {
            $found | Remove-WindowsCapability -Online -ErrorAction Stop
            "$selector removed successfully." | Out-File -FilePath $logfile -Append
        } catch {
            "$selector removal failed. Error: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
        }
    } else {
        "$selector not installed." | Out-File -FilePath $logfile -Append
    }
}

"Finished RemoveCapabilities.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append
