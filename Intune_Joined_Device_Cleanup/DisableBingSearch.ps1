# Disable Bing search in Start menu and Search box

# System-wide policy (all users)
$regPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
New-Item -Path $regPath1 -ErrorAction SilentlyContinue
Set-ItemProperty -Path $regPath1 -Name "DisableSearchBoxSuggestions" -Value 1 -Force

# Current user only
$regPath2 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
Set-ItemProperty -Path $regPath2 -Name "BingSearchEnabled" -Value 0 -Force
Set-ItemProperty -Path $regPath2 -Name "CortanaConsent" -Value 0 -Force
