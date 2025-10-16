# Update these
$Url = "<URL>
$ShortcutName = "PLS <DOMAIN>0"

$PublicDesktop = "$env:<DOMAIN>\<USERNAME>"
$ShortcutPath = Join-Path $PublicDesktop $ShortcutName
New-Item -ItemType Directory -Path $PublicDesktop -Force | Out-Null

$lines = @(
    "[InternetShortcut]"
    "URL=$Url"
    "IDList="
    "HotKey=0"
)
$lines | Out-File -FilePath $ShortcutPath -Encoding ASCII -Force

