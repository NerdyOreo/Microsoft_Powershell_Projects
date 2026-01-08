# RemovePackages.ps1
# Removes selected built-in Appx packages for all users

$scriptFolder = "C:\Windows\Setup\Scripts"
New-Item -Path $scriptFolder -ItemType Directory -Force | Out-Null
$logfile = "$scriptFolder\RemovePackages.log"

"Starting RemovePackages.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append

$selectors = @(
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

$installed = Get-AppxProvisionedPackage -Online

foreach ($selector in $selectors) {
    $found = $installed | Where-Object { $_.DisplayName -eq $selector }
    if ($found) {
        try {
            $found | Remove-AppxProvisionedPackage -Online -AllUsers -ErrorAction Stop
            "$selector removed successfully." | Out-File -FilePath $logfile -Append
        } catch {
            "$selector removal failed. Error: $($_.Exception.Message)" | Out-File -FilePath $logfile -Append
        }
    } else {
        "$selector not installed." | Out-File -FilePath $logfile -Append
    }
}

"Finished RemovePackages.ps1 at $(Get-Date)" | Out-File -FilePath $logfile -Append
