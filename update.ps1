# ============ 前端面试题知识库 一键更新脚本 ============
# 用途：重新抓取 fe.ecool.fun 最新题库并重新生成网站。
# 用法：在 PowerShell 中执行  & 'update.ps1'
$ErrorActionPreference = 'Stop'

$kb = $PSScriptRoot
$scriptsDir = "$kb\scripts"
$cfgPath = "$kb\_config\cookies.json"
$headers = @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'; 'Referer'='https://fe.ecool.fun/topic-list'}

# ---------- 1. 校验登录凭证 ----------
Write-Host '=== [1/5] 校验登录凭证 cookies.json ==='
if (-not (Test-Path $cfgPath)) {
    Write-Host '错误：缺少 _config\cookies.json，请先让用户登录网站并写入最新 cookie。'
    exit 1
}
$cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.Cookies.Add((New-Object System.Net.Cookie('utoken', $cfg.utoken, '/', 'fe.ecool.fun'))) | Out-Null
$session.Cookies.Add((New-Object System.Net.Cookie('utoken.sig', $cfg.'utoken.sig', '/', 'fe.ecool.fun'))) | Out-Null
$session.Cookies.Add((New-Object System.Net.Cookie('csrfToken', $cfg.csrfToken, '/', 'fe.ecool.fun'))) | Out-Null

$cookieOk = $false
try {
    $r = Invoke-RestMethod -Uri 'https://fe.ecool.fun/api/exercise/list?vid=9&exerciseCate=0&pageNum=1&pageSize=1&ignoreMaster=1&orderBy=default&order=desc' -WebSession $session -Headers $headers -TimeoutSec 20
    if ($r.code -eq 0 -and $r.data.list.Count -gt 0) { $cookieOk = $true }
} catch { }
if (-not $cookieOk) {
    Write-Host '登录凭证已失效（或网络异常）。需要更新 cookie：'
    Write-Host '  1. 请用户用浏览器登录 https://fe.ecool.fun/topic-list'
    Write-Host '  2. 从浏览器开发者工具（F12 -> Application -> Cookies）复制三个值：'
    Write-Host '     utoken、utoken.sig、csrfToken'
    Write-Host "  3. 更新 $cfgPath 文件后重新运行本脚本"
    exit 1
}
Write-Host "凭证有效（更新于 $($cfg.updatedAt)），继续更新。"

# ---------- 2. 抓取题目列表 ----------
Write-Host '=== [2/5] 抓取题目列表（26 个分类）==='
& (Join-Path $scriptsDir 'fetch_list.ps1')
if (-not $?) { Write-Host '列表抓取异常，中止。'; exit 1 }

# ---------- 3. 抓取题目详情 ----------
Write-Host '=== [3/5] 抓取题目详情（全部题目答案）==='
& (Join-Path $scriptsDir 'fetch_details.ps1')
if ($?) { Write-Host '详情抓取完成。' }

# ---------- 4. 重新生成网站 ----------
Write-Host '=== [4/5] 生成网站（样式/首页/分类页）==='
& (Join-Path $scriptsDir 'gen_assets.ps1')
Write-Host '=== [5/5] 生成题目详情页 ==='
& (Join-Path $scriptsDir 'gen_details.ps1')

# ---------- 验证 ----------
Write-Host ''
Write-Host '=== 验证结果 ==='
$list = Get-Content "$kb\_raw\topic_list.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$topicCount = @($list.PSObject.Properties).Count
$detailCount = (Get-ChildItem "$kb\_raw\answers" -Filter *.json).Count
$catPageCount = (Get-ChildItem "$kb\categories" -Filter *.html).Count
$qPageCount = (Get-ChildItem "$kb\questions" -Filter *.html).Count
Write-Host "题目总数：$topicCount"
Write-Host "详情 JSON：$detailCount"
Write-Host "分类页：$catPageCount"
Write-Host "详情页：$qPageCount"

# 未归类题目检查（提示网站可能新增分类）
$unclassified = @($list.PSObject.Properties | Where-Object { @($_.Value.tags | Where-Object { $_ -ne '全部' }).Count -eq 0 })
if ($unclassified.Count -gt 0) {
    Write-Host "注意：$($unclassified.Count) 道题未归属任何具体分类，网站可能新增了分类。请检查 fetch_list.ps1 的 tags 数组是否缺少新分类（tagId 可通过网站点击分类标签观察 URL 获取）。"
} else {
    Write-Host '所有题目均已正确归类。'
}

Write-Host ''
Write-Host '=== 更新完成 ==='
