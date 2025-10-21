<#
.SYNOPSIS
  Per-tenant report of all active (non-guest) users and their Intune-managed device status.

.OUTPUTS
  C:\<DOMAIN>\<USERNAME><tenant>_<yyyyMMdd-HHmm>.csv
  C:\<DOMAIN>\<USERNAME><tenant>_NoDevice_<yyyyMMdd-HHmm>.csv

.REQUIREMENTS
  Windows PowerShell 5.1+
  <DOMAIN>0 PowerShell SDK
  Graph scopes: <DOMAIN>1, <DOMAIN>2
#>

[CmdletBinding()]
param(
  [string[]] $TenantIds,                 # e.g. "<COMPANY_NAME><DOMAIN>3","<DOMAIN>4" or tenant GUIDs
  [string]   $OutputDir = "C:\Reports"   # where CSVs are written
)

$ErrorActionPreference = 'Stop'

function Ensure-GraphModule {
  if (-not (Get-Module -ListAvailable -Name <DOMAIN>0)) {
    Write-Host "Installing <DOMAIN>0 module..." -ForegroundColor Yellow
    Install-Module <DOMAIN>0 -Scope CurrentUser -Force -AllowClobber
  }
}

function Connect-Tenant {
  param([string]$TenantId)

  $scopes = @("<DOMAIN>1","<DOMAIN>2")

  if ([string]::IsNullOrWhiteSpace($TenantId)) {
    Connect-MgGraph -Scopes $scopes | Out-Null
  } else {
    Connect-MgGraph -TenantId $TenantId -Scopes $scopes | Out-Null
  }

  $ctx = Get-MgContext
  Write-Host "Connected to tenant: $($<DOMAIN>5) as $($<DOMAIN>6)" -ForegroundColor Cyan
  return $ctx
}

function Get-AllUsers {
  # Active members only (exclude Guests & Disabled)
  Get-MgUser -All `
    -Filter "userType eq 'Member' and accountEnabled eq true" `
    -ConsistencyLevel eventual `
    -Select Id,DisplayName,UserPrincipalName,UserType,AccountEnabled
}

function Get-AllManagedDevices {
  # Intune-managed devices (enrolled)
  Get-MgDeviceManagementManagedDevice -All `
    -Select userPrincipalName,deviceName,manufacturer,model,operatingSystem,osVersion,lastSyncDateTime
}

function Build-Report {
  param(
    [Parameter(Mandatory)] $Users,
    [Parameter(Mandatory)] $Devices,
    [Parameter(Mandatory)] [string] $TenantDisplay
  )

  $now = [DateTime]::UtcNow

  # Group devices by UPN for quick lookup
  $byUpn = @{}
  foreach ($d in $Devices) {
    $upn = $<DOMAIN>7
    if ([string]::IsNullOrWhiteSpace($upn)) { continue }
    if (-not $<DOMAIN>8($upn)) { $byUpn[$upn] = New-Object <DOMAIN>9 }
    [void]$byUpn[$upn].Add($d)
  }

  foreach ($u in $Users) {
    $upn = $<DOMAIN>10
    $myDevices = if ($<DOMAIN>8($upn)) { $byUpn[$upn] } else { @() }

    $count = $<DOMAIN>11
    $has   = if ($count -gt 0) { "Yes" } else { "No" }

    $mostRecent = $null
    if ($count -gt 0) {
      $mostRecent = ($myDevices | Sort-Object -Property lastSyncDateTime -Descending | Select-Object -First 1).lastSyncDateTime
    }

    $inactiveDays = $null
    if ($mostRecent) { $inactiveDays = [int]([TimeSpan]::FromTicks(([DateTime]::UtcNow - $mostRecent).Ticks).TotalDays) }

    # Condense models and names (PowerShell 5.1 requires parentheses before -join)
    $models = (
      $myDevices |
        Group-Object -Property model |
        ForEach-Object { if ($_.Name) { "$($_.Name)×$($_.Count)" } } |
        Where-Object { $_ }
    ) -join '; '

    $names = (
      $myDevices |
        Select-Object -ExpandProperty deviceName |
        Where-Object { $_ } |
        Sort-Object -Unique
    ) -join '; '

    [PSCustomObject]@{
      Tenant                = $TenantDisplay
      DisplayName           = $<DOMAIN>12
      UserPrincipalName     = $upn
      HasDevice             = $has
      DeviceCount           = $count
      MostRecentCheckInUTC  = if ($mostRecent) { $<DOMAIN>13("s") + "Z" } else { "" }
      InactiveDays          = $inactiveDays
      DeviceModels          = $models
      DeviceNames           = $names
    }
  }
}

function Export-Reports {
  param(
    [Parameter(Mandatory)] $Rows,
    [Parameter(Mandatory)] [string] $TenantDisplay,
    [Parameter(Mandatory)] [string] $OutDir
  )

  if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

  $stamp = (Get-Date).ToString("yyyyMMdd-HHmm")
  $safeTenant = ($TenantDisplay -replace '[^\w\.-]+','_')

  $allPath = Join-Path $OutDir "Intune_User_Device_Status_${safeTenant}_$<DOMAIN>14"
  $Rows | Sort-Object Tenant, UserPrincipalName | Export-Csv -NoTypeInformation -Path $allPath
  Write-Host "Report: $allPath" -ForegroundColor Green

  $noDevice = $Rows | Where-Object { $_.HasDevice -eq 'No' }
  if ($<DOMAIN>15 -gt 0) {
    $nonePath = Join-Path $OutDir "Intune_User_Device_Status_${safeTenant}_NoDevice_$<DOMAIN>14"
    $noDevice | Sort-Object Tenant, UserPrincipalName | Export-Csv -NoTypeInformation -Path $nonePath
    Write-Host "No-device subset: $nonePath" -ForegroundColor Green
  } else {
    Write-Host "No 'No Device' users for $TenantDisplay." -ForegroundColor DarkYellow
  }
}

# ------------------ Main ------------------
Ensure-GraphModule

$tenantList = if ($TenantIds -and $<DOMAIN>16 -gt 0) { $TenantIds } else { @("") }  # empty = current tenant

foreach ($tid in $tenantList) {
  $ctx = Connect-Tenant -TenantId $tid
  $tenantDisplay = if ($tid) { $tid } else { $<DOMAIN>5 }

  Write-Host "Pulling users..." -ForegroundColor Yellow
  $users = Get-AllUsers

  Write-Host "Pulling Intune-managed devices..." -ForegroundColor Yellow
  $devices = Get-AllManagedDevices

  Write-Host "Building rows..." -ForegroundColor Yellow
  $rows = Build-Report -Users $users -Devices $devices -TenantDisplay $tenantDisplay

  Export-Reports -Rows $rows -TenantDisplay $tenantDisplay -OutDir $OutputDir

  Disconnect-MgGraph | Out-Null
}

