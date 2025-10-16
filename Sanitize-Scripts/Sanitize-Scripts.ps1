param(
  [string]$Path,
  [string[]]$Files,
  [Parameter(Mandatory=$true)][string]$OutputDir,

  [switch]$Recurse,
  [string[]]$Include = @('*.ps1'),
  [string[]]$Exclude = @(),

  [string[]]$DomainWhitelist = @('github.com','api.github.com','microsoft.com','learn.microsoft.com','powershellgallery.com'),
  [string[]]$CompanyNamePatterns = @('Prime Lender Solutions','primelender','corp.local','mycompany','contoso','acmecorp'),

  [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------- Collect files ----------------
$targetFiles = @()

if ($Files -and $Files.Count -gt 0) {
  $targetFiles = $Files | Where-Object { Test-Path -LiteralPath $_ }
  $missing = $Files | Where-Object { -not (Test-Path -LiteralPath $_) }
  if ($missing) {
    Write-Warning ("Not found and skipped:`n - " + ($missing -join "`n - "))
  }
} elseif ($Path) {
  if (-not (Test-Path -LiteralPath $Path)) { throw "Path not found: $Path" }
  $items = Get-ChildItem -LiteralPath $Path -Recurse:$Recurse -File -Include $Include -ErrorAction SilentlyContinue
  if ($Exclude.Count -gt 0) {
    $items = $items | ForEach-Object {
      $f = $_.FullName
      if (-not ($Exclude | Where-Object { $f -like $_ })) { $_ }
    }
  }
  $targetFiles = $items.FullName
} else {
  Write-Host "Specify -Files or -Path."; return
}

if (-not $targetFiles -or $targetFiles.Count -eq 0) {
  Write-Host "No matching files found."; return
}

# ---------------- Helpers ----------------
$regexOptsNone = [System.Text.RegularExpressions.RegexOptions]::None
$regexOptsI    = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$regexOptsS    = [System.Text.RegularExpressions.RegexOptions]::Singleline
$regexOptsIS   = $regexOptsI -bor $regexOptsS

function New-MappingList { New-Object System.Collections.Generic.List[pscustomobject] }

function Replace-And-Map {
  param(
    [ref]$Text,
    [string]$Pattern,
    [string]$Placeholder,
    [string]$Name,
    [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None,
    [switch]$IndexEach,
    [scriptblock]$FilterScript
  )
  $mappingLocal = @{}
  $matches = [regex]::Matches($Text.Value, $Pattern, $Options)
  if ($matches.Count -eq 0) { return @() }

  $unique = @()
  foreach ($m in $matches) {
    $val = $m.Value
    if ($FilterScript) { if (-not (& $FilterScript $val)) { continue } }
    if (-not $unique.Contains($val)) { $unique += $val }
  }
  if ($unique.Count -eq 0) { return @() }

  $i = 0
  foreach ($u in $unique) {
    $token = if ($IndexEach) { "{0}{1}" -f $Placeholder, $i } else { $Placeholder }
    $Text.Value = $Text.Value -replace [regex]::Escape($u), $token
    $mappingLocal[$u] = $token
    $i++
  }

  return $mappingLocal.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ Pattern=$Name; Original=$_.Key; Replacement=$_.Value }
  }
}

function Out-MappingFiles {
  param(
    [System.Collections.Generic.List[pscustomobject]]$Mapping,
    [string]$BasePathNoExt
  )
  $jsonPath = "$BasePathNoExt.mapping.json"
  $csvPath  = "$BasePathNoExt.mapping.csv"
  $Mapping | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
  $Mapping | Export-Csv -NoTypeInformation -Path $csvPath -Encoding UTF8
}

# ---------------- Company regex ----------------
$companyAlternations = @()
foreach ($c in $CompanyNamePatterns) {
  if ($c -match '[\.\^\$\*\+\?\(\)\[\]\{\}\|\\]') { $companyAlternations += $c }
  else { $companyAlternations += [regex]::Escape($c) }
}
$companyRegex = if ($companyAlternations) { "(?i)\b(?:$($companyAlternations -join '|'))\b" } else { $null }

# ---------------- Patterns (order matters) ----------------
$patterns = @(
  @{ Name='PrivateKeyBlock';     Pattern='-----BEGIN [^-]*PRIVATE KEY-----.*?-----END [^-]*PRIVATE KEY-----'; Placeholder='<PRIVATE_KEY_BLOCK>'; Options=$regexOptsIS },
  @{ Name='CertificateBlock';    Pattern='-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----';           Placeholder='<CERTIFICATE_BLOCK>'; Options=$regexOptsIS },

  @{ Name='BearerJWT';           Pattern='(?i)\b(authorization|auth)\s*[:=]\s*([""]?)bearer\s+[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+([""]?)'; Placeholder='<BEARER_JWT>'; Options=$regexOptsIS },
  @{ Name='SASToken';            Pattern='(?i)(sv|ss|srt|sp|se|st|spr|sig)=[^&\s"]{6,}';                      Placeholder='<SAS_PARAM>'; Options=$regexOptsI },
  @{ Name='Base64Long';          Pattern='\b[A-Za-z0-9+/]{40,}={0,2}\b';                                       Placeholder='<BASE64_BLOB>'; Options=$regexOptsNone },

  @{ Name='CredentialPair';      Pattern='(?i)\b(password|pwd|passphrase|secret|apikey|api_key|token|pat|sas|connstring|connectionstring|clientsecret|client_secret)\b\s*[:=]\s*([""]?)[^""\s,;]+([""]?)'; Placeholder='<CREDENTIAL_PAIR>'; Options=$regexOptsI },
  @{ Name='ConnStringKey';       Pattern='(?i)\b(server|data\s*source|addr|address|network\s*address|database|initial\s*catalog|user\s*id|uid|password|pwd|auth|application\s*intent|trusted_connection|integrated\s*security)\s*=\s*[^;]+'; Placeholder='<CONN_KV>'; Options=$regexOptsI },

  @{ Name='AzureTenantId';       Pattern='(?i)\b(tenant(id)?|directory(id)?)\b\s*[:=]\s*([""]?)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'; Placeholder='<AZURE_TENANT_ID>'; Options=$regexOptsI },
  @{ Name='AzureSubscriptionId'; Pattern='(?i)\b(subscription(id)?)\b\s*[:=]\s*([""]?)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b';        Placeholder='<AZURE_SUBSCRIPTION_ID>'; Options=$regexOptsI },
  @{ Name='AzureClientAppId';    Pattern='(?i)\b(client(id)?|app(id)?)\b\s*[:=]\s*([""]?)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b';      Placeholder='<AZURE_CLIENT_ID>'; Options=$regexOptsI },
  @{ Name='AzureResourceId';     Pattern='(?i)/subscriptions/[0-9a-f-]{36}/resourcegroups/[^/\s]+/providers/[^/\s]+/[^/\s]+(?:/[^/\s]+)*';                     Placeholder='<AZURE_RESOURCE_ID>'; Options=$regexOptsI },

  @{ Name='Email';               Pattern='\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b';               Placeholder='<EMAIL>'; Options=$regexOptsNone },
  @{ Name='DomainBackslashUser'; Pattern='\b[A-Za-z0-9._\-]+\\[A-Za-z0-9._$\-]+\b';                            Placeholder='<DOMAIN>\<USERNAME>'; Options=$regexOptsNone },
  @{ Name='UPNUser';             Pattern='\b[A-Za-z0-9._\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b';                 Placeholder='<UPN>'; Options=$regexOptsNone },

  @{ Name='IPv4';                Pattern='\b(?:\d{1,3}\.){3}\d{1,3}\b';                                         Placeholder='<IP>'; Options=$regexOptsNone },
  @{ Name='MAC';                 Pattern='\b(?:[0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}\b';                         Placeholder='<MAC>'; Options=$regexOptsNone },
  @{ Name='GUID';                Pattern='\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b'; Placeholder='<GUID>'; Options=$regexOptsNone },
  @{ Name='UNC';                 Pattern='\\\\[A-Za-z0-9._$\-]+\\[A-Za-z0-9._$\-\\]+';                          Placeholder='<UNC_PATH>'; Options=$regexOptsNone },
  @{ Name='URL';                 Pattern='https?://\S+';                                                         Placeholder='<URL>'; Options=$regexOptsI },

  @{ Name='LDAP_DN';             Pattern='(?i)\b(?:CN|OU|DC)=[^,=]+(?:,(?:CN|OU|DC)=[^,=]+)+';                 Placeholder='<LDAP_DN>'; Options=$regexOptsI },

  @{ Name='Domain';              Pattern='\b(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}\b';                               Placeholder='<DOMAIN>'; Options=$regexOptsNone }
)

# ---------------- Ensure output folder ----------------
New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

# ---------------- Process files ----------------
$summary = @()

foreach ($file in $targetFiles) {
  Write-Host ""
  Write-Host ("--- Processing: {0}" -f $file)

  try { $raw = Get-Content -LiteralPath $file -Raw -Encoding UTF8 }
  catch {
    Write-Warning ("Read failed: " + $_.Exception.Message)
    $summary += [pscustomobject]@{ File=$file; Status='Read Error'; Replacements=0; Output=$null }
    continue
  }

  $textRef = [ref] $raw
  $map = New-MappingList

  foreach ($p in $patterns) {
    $name        = $p.Name
    $pattern     = $p.Pattern
    $placeholder = $p.Placeholder
    $options     = $p.Options

    switch ($name) {
      'Domain' {
        $localWhitelist = $DomainWhitelist
        $filter = { param($value) -not ($localWhitelist -and ($localWhitelist | Where-Object { $_ -ieq $value })) }
        $entries = Replace-And-Map -Text $textRef -Pattern $pattern -Placeholder $placeholder -Name $name -Options $options -IndexEach -FilterScript $filter
      }
      default {
        if ($name -eq 'Email' -and $companyRegex) {
          $companyEntries = Replace-And-Map -Text $textRef -Pattern $companyRegex -Placeholder '<COMPANY_NAME>' -Name 'CompanyName' -Options $regexOptsI -IndexEach
          foreach ($e in $companyEntries) { $map.Add($e) }
        }
        $index = $true
        if ($name -in @('Email','UPNUser','DomainBackslashUser','IPv4','GUID','URL','UNC','MAC','ConnStringKey','PrivateKeyBlock','CertificateBlock','LDAP_DN','AzureResourceId')) { $index = $false }
        $entries = Replace-And-Map -Text $textRef -Pattern $pattern -Placeholder $placeholder -Name $name -Options $options -IndexEach:$index
      }
    }
    foreach ($e in $entries) { $map.Add($e) }
  }

  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
  $outPath  = Join-Path $OutputDir "$baseName.sanitized.ps1"
  $mapBase  = Join-Path $OutputDir $baseName
  $jsonPath = "$mapBase.mapping.json"
  $csvPath  = "$mapBase.mapping.csv"

  $status = 'OK'
  if ($WhatIf) {
    $status = 'DRY RUN'
    Write-Host ("(WhatIf) Would write: {0}" -f $outPath)
  } else {
    try {
      $textRef.Value | Out-File -FilePath $outPath -Encoding UTF8 -Force
      $map | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
      $map | Export-Csv -NoTypeInformation -Path $csvPath -Encoding UTF8
      Write-Host ("Saved: {0}" -f $outPath)
      Write-Host ("Mapping: {0} / {1}" -f $jsonPath, $csvPath)
    } catch {
      Write-Warning ("Write failed: " + $_.Exception.Message)
      $status = 'Write Error'
    }
  }

  $summary += [pscustomobject]@{
    File         = $file
    Status       = $status
    Replacements = $map.Count
    Output       = $outPath
  }
}

Write-Host ""
Write-Host "==== SUMMARY ===="
$summary | Format-Table -AutoSize
