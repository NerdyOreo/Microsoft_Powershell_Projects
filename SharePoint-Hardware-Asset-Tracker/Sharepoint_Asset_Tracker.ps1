# ===== Settings =====
$SiteUrl   = "https://yourtenant.sharepoint.com/sites/YourSiteName"
$listTitle = "Device Inventory"
# Connect-PnPOnline -Url $SiteUrl -Interactive   # (run separately before this script)

# ---------- helpers ----------
function Ensure-Field {
    param(
        [string]$ListTitle, [string]$DisplayName, [string]$InternalName,
        [ValidateSet('Text','Note','DateTime','Choice','Number','Boolean','User')] [string]$Type,
        [string[]]$Choices = @(),
        [switch]$AddToDefaultView,
        [switch]$DateOnly
    )
    $existing = Get-PnPField -List $ListTitle -Identity $InternalName -ErrorAction SilentlyContinue
    if (-not $existing) {
        switch ($Type) {
            'Choice'   { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type Choice  -Choices $Choices -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'Text'     { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type Text    -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'Note'     { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type Note    -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'DateTime' { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type DateTime -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'Number'   { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type Number  -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'Boolean'  { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type Boolean -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
            'User'     { Add-PnPField -List $ListTitle -DisplayName $DisplayName -InternalName $InternalName -Type User    -AddToDefaultView:$AddToDefaultView.IsPresent | Out-Null }
        }
    }
    if ($Type -eq 'DateTime' -and $DateOnly) {
        try { Set-PnPField -List $ListTitle -Identity $InternalName -Values @{ DisplayFormat = 0 } } catch {}
    }
}

function Ensure-View {
    param([string]$ListTitle,[string]$ViewTitle,[string[]]$Fields,[string]$CamlQuery)
    $v = Get-PnPView -List $ListTitle -Identity $ViewTitle -ErrorAction SilentlyContinue
    if (-not $v) {
        Add-PnPView -List $ListTitle -Title $ViewTitle -Fields $Fields -Query $CamlQuery | Out-Null
    } else {
        Set-PnPView -List $ListTitle -Identity $ViewTitle -Fields $Fields -Values @{ ViewQuery = $CamlQuery } | Out-Null
    }
}

function Remove-FromDefaultView {
    param([string]$ListTitle,[string[]]$Fields)
    $v = Get-PnPView -List $ListTitle -Identity "All Items" -ErrorAction SilentlyContinue
    if ($v) { foreach ($f in $Fields) { try { Remove-PnPViewField -List $ListTitle -Identity $v -Field $f -ErrorAction SilentlyContinue } catch {} } }
}

# ---------- list settings ----------
Set-PnPList -Identity $listTitle -EnableVersioning $true -EnableMinorVersions $false -MajorVersions 500 | Out-Null

# Hide/relax "Title"
try { Set-PnPField -List $listTitle -Identity "Title" -Values @{ Required = $false } } catch {}
try { Remove-FromDefaultView -ListTitle $listTitle -Fields @("Title") } catch {}

# ---------- columns (EXACT spec) ----------
Ensure-Field -ListTitle $listTitle -DisplayName "Employee Name"          -InternalName "EmployeeName"     -Type User    -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Company"                -InternalName "Company"          -Type Choice  -Choices @("CompanyA","CompanyB") -AddToDefaultView

Ensure-Field -ListTitle $listTitle -DisplayName "Laptop Model"           -InternalName "LaptopModel"      -Type Text    -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Laptop MAC Address"     -InternalName "LaptopMac"        -Type Text    -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "New or Used"            -InternalName "NewOrUsed"        -Type Choice  -Choices @("New","Used") -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Previous Owner"         -InternalName "PreviousOwner"    -Type Text    -AddToDefaultView

Ensure-Field -ListTitle $listTitle -DisplayName "Monitor(s) Model"       -InternalName "MonitorModel"     -Type Choice  -Choices @("None","Lenovo","Dell","Other") -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Monitor(s) Quantity"    -InternalName "MonitorQty"       -Type Choice  -Choices @("0","1","2") -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Dock Included?"         -InternalName "DockIncluded"     -Type Boolean -AddToDefaultView

Ensure-Field -ListTitle $listTitle -DisplayName "Date Ordered"           -InternalName "DateOrdered"      -Type DateTime -DateOnly -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Order #"                -InternalName "OrderNumber"      -Type Text    -AddToDefaultView
Ensure-Field -ListTitle $listTitle -DisplayName "Tracking Number"        -InternalName "TrackingNumber"   -Type Text    -AddToDefaultView

Ensure-Field -ListTitle $listTitle -DisplayName "Status"                 -InternalName "Status2"          -Type Choice  -Choices @("Pending","Issued","Returned","Replaced") -AddToDefaultView

# ---------- defaults ----------
try { Set-PnPField -List $listTitle -Identity "MonitorModel" -Values @{ DefaultValue = "None" } } catch {}
try { Set-PnPField -List $listTitle -Identity "MonitorQty"   -Values @{ DefaultValue = "0" } } catch {}
try { Set-PnPField -List $listTitle -Identity "NewOrUsed"    -Values @{ DefaultValue = "New" } } catch {}
try { Set-PnPField -List $listTitle -Identity "Status2"      -Values @{ DefaultValue = "Pending" } } catch {}

# ---------- formatting ----------
$statusJson = @'
{
  "$schema": "https://developer.microsoft.com/json-schemas/sp/v2/column-formatting.schema.json",
  "elmType": "div",
  "attributes": {
    "class": "=if(@currentField == 'Issued','sp-field-severity--good', if(@currentField == 'Pending','sp-field-severity--low', if(@currentField == 'Returned','sp-field-severity--warning','sp-field-severity--blocked')))"
  },
  "style": { "display": "inline-block", "padding": "2px 8px", "border-radius": "12px" },
  "children": [{ "elmType": "span", "txtContent": "@currentField" }]
}
'@
try { Set-PnPField -List $listTitle -Identity "Status2" -Values @{ CustomFormatter = $statusJson } } catch {}

# ---------- views ----------
$base = @(
  "Company","EmployeeName",
  "LaptopModel","LaptopMac","NewOrUsed","PreviousOwner",
  "MonitorModel","MonitorQty","DockIncluded",
  "DateOrdered","OrderNumber","TrackingNumber",
  "Status2"
)

Ensure-View -ListTitle $listTitle -ViewTitle "Pending"                   -Fields $base -CamlQuery "<Where><Eq><FieldRef Name='Status2'/><Value Type='Choice'>Pending</Value></Eq></Where>"
Ensure-View -ListTitle $listTitle -ViewTitle "Issued"                    -Fields $base -CamlQuery "<Where><Eq><FieldRef Name='Status2'/><Value Type='Choice'>Issued</Value></Eq></Where>"
Ensure-View -ListTitle $listTitle -ViewTitle "Orders - Last 30 Days"     -Fields $base -CamlQuery "<Where><Geq><FieldRef Name='DateOrdered'/><Value IncludeTimeValue='FALSE' Type='DateTime'><Today OffsetDays='-30' /></Value></Geq></Where>"
Ensure-View -ListTitle $listTitle -ViewTitle "CompanyA"                  -Fields $base -CamlQuery "<Where><Eq><FieldRef Name='Company'/><Value Type='Choice'>CompanyA</Value></Eq></Where>"
Ensure-View -ListTitle $listTitle -ViewTitle "CompanyB"                  -Fields $base -CamlQuery "<Where><Eq><FieldRef Name='Company'/><Value Type='Choice'>CompanyB</Value></Eq></Where>"

Write-Host "Device Inventory built with your fields. Title hidden, defaults set, views ready."
