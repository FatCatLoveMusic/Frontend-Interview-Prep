$ErrorActionPreference = 'Stop'
$kb = Split-Path $PSScriptRoot -Parent
$outDir = "$kb\_raw"
$cfg = Get-Content "$kb\_config\cookies.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$cookie1 = New-Object System.Net.Cookie('utoken', $cfg.utoken, '/', 'fe.ecool.fun')
$cookie2 = New-Object System.Net.Cookie('utoken.sig', $cfg.'utoken.sig', '/', 'fe.ecool.fun')
$cookie3 = New-Object System.Net.Cookie('csrfToken', $cfg.csrfToken, '/', 'fe.ecool.fun')
$session.Cookies.Add($cookie1) | Out-Null
$session.Cookies.Add($cookie2) | Out-Null
$session.Cookies.Add($cookie3) | Out-Null
$headers = @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'; 'Referer'='https://fe.ecool.fun/topic-list'; 'Accept'='application/json'}

$list = Get-Content "$outDir\topic_list.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$keys = @($list.PSObject.Properties.Name)
$total = $keys.Count
Write-Host "TOTAL keys: $total"

$i = 0
$fail = @()
foreach ($key in $keys) {
  $i++
  $outFile = "$outDir\answers\$key.json"
  if (Test-Path $outFile) { continue }
  $url = "https://fe.ecool.fun/api/exercise/practice/detail?vid=9&difficulty=&exerciseCate=0&ignoreMaster=1&order=desc&orderBy=default&tagId=0&exerciseKey=$key"
  try {
    $r = Invoke-RestMethod -Uri $url -WebSession $session -Headers $headers -TimeoutSec 30
  } catch {
    $fail += $key
    Write-Host "ERROR $key : $($_.Exception.Message)"
    Start-Sleep -Milliseconds 1500
    continue
  }
  if ($r.code -ne 0) {
    $fail += $key
    Write-Host "API error $key code=$($r.code) msg=$($r.message)"
    continue
  }
  $r.data | ConvertTo-Json -Depth 10 | Out-File -Encoding UTF8 $outFile
  if (($i % 25) -eq 0) { Write-Host "progress $i/$total" }
  Start-Sleep -Milliseconds 80
}
Write-Host "DONE total=$total fail=$($fail.Count)"
if ($fail.Count -gt 0) { $fail | Out-File -Encoding UTF8 "$outDir\failed_keys.txt"; Write-Host "failed keys saved to failed_keys.txt" }
