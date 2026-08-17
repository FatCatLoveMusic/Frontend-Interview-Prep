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
$headers = @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'; 'Referer'='https://fe.ecool.fun/topic-list'}

$tags = @(
  @{id=0;  name='全部'},
  @{id=10; name='JavaScript'},
  @{id=11; name='CSS'},
  @{id=12; name='HTML'},
  @{id=13; name='React.js'},
  @{id=14; name='Vue.js'},
  @{id=15; name='算法'},
  @{id=16; name='计算机网络'},
  @{id=17; name='趣味题'},
  @{id=18; name='Node.js'},
  @{id=19; name='Typescript'},
  @{id=20; name='性能优化'},
  @{id=21; name='前端安全'},
  @{id=23; name='小程序'},
  @{id=24; name='ES6'},
  @{id=26; name='编程题'},
  @{id=27; name='设计模式'},
  @{id=28; name='工程化'},
  @{id=29; name='工具'},
  @{id=30; name='计算机基础'},
  @{id=31; name='leetcode'},
  @{id=32; name='选择题'},
  @{id=74; name='跨端技术'},
  @{id=75; name='场景题'},
  @{id=77; name='AI相关'},
  @{id=78; name='Agent'}
)

$allTopics = @{}
$totalRequests = 0

foreach ($tag in $tags) {
  $page = 1
  $totalPages = 1
  while ($true) {
    $tagParam = if ($tag.id -eq 0) { '' } else { $tag.id }
    $url = "https://fe.ecool.fun/api/exercise/list?vid=9&tagId=$tagParam&exerciseCate=0&pageNum=$page&pageSize=10&ignoreMaster=1&difficulty=&orderBy=default&order=desc"
    try {
      $r = Invoke-RestMethod -Uri $url -WebSession $session -Headers $headers -TimeoutSec 30
    } catch {
      Write-Host "ERROR tag=$($tag.name) page=$page : $($_.Exception.Message)"
      Start-Sleep -Milliseconds 1000
      continue
    }
    $totalRequests++
    if ($r.code -ne 0) {
      Write-Host "API error tag=$($tag.name) page=$page code=$($r.code) msg=$($r.message)"
      break
    }
    foreach ($item in $r.data.list) {
      $key = $item.exerciseKey
      if (-not $allTopics.ContainsKey($key)) {
        $allTopics[$key] = @{ title = $item.title; category = $item.category; level = $item.level; tags = @() }
      }
      $allTopics[$key].tags += $tag.name
    }
    $totalPages = [Math]::Ceiling($r.data.totalCount / 10)
    if ($page -ge $totalPages) { break }
    $page++
    Start-Sleep -Milliseconds 120
  }
  Write-Host "done tag=$($tag.name) count=$($r.data.totalCount) pages=$totalPages"
}

$allTopics | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 "$outDir\topic_list.json"
Write-Host "TOTAL topics: $($allTopics.Count), requests: $totalRequests"
Write-Host "SAVED to $outDir\topic_list.json"
