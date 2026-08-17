# ============ 公共模块：配置与工具函数 ============
$ErrorActionPreference = 'Stop'

$kb = Split-Path $PSScriptRoot -Parent
$rawDir = "$kb\_raw"
$assetsDir = "$kb\assets"
$catDir = "$kb\categories"
$qDir = "$kb\questions"

$tags = @('JavaScript','CSS','HTML','React.js','Vue.js','算法','计算机网络','趣味题','Node.js','Typescript','性能优化','前端安全','小程序','ES6','编程题','设计模式','工程化','工具','计算机基础','leetcode','选择题','跨端技术','场景题','AI相关','Agent')

function Escape-Html([string]$s) {
    return $s.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function Convert-Inline([string]$s) {
    $t = Escape-Html $s
    $t = [regex]::Replace($t, '`([^`\n]+)`', '<code>$1</code>')
    $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
    $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)\s]+)\)', '<a href="$2" target="_blank" rel="noopener">$1</a>')
    return $t
}

function Convert-Markdown([string]$md) {
    if ([string]::IsNullOrEmpty($md)) { return '' }
    $lines = $md -split "`n"
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    $n = $lines.Length
    while ($i -lt $n) {
        $line = $lines[$i]
        # 代码块
        if ($line -match '^```') {
            $codeLines = @()
            $i++
            while ($i -lt $n -and $lines[$i] -notmatch '^```') {
                $codeLines += $lines[$i]
                $i++
            }
            $i++
            [void]$sb.AppendLine('<pre class="code-block"><code>' + (Escape-Html ($codeLines -join "`n")) + '</code></pre>')
            continue
        }
        # 表格
        if ($line -match '^\s*\|.*\|\s*$') {
            $rows = @()
            while ($i -lt $n -and $lines[$i] -match '^\s*\|.*\|\s*$') {
                $rows += $lines[$i]
                $i++
            }
            $headerRow = $null
            $bodyRows = @()
            foreach ($r in $rows) {
                $trimmed = $r.Trim()
                $cells = @($trimmed.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
                if ($cells.Count -ge 1 -and ($cells | Where-Object { $_ -match '^:-{3,}:?$' -or $_ -match '^-{3,}:?$' }).Count -eq $cells.Count) {
                    continue
                }
                if ($null -eq $headerRow) { $headerRow = $cells } else { $bodyRows += ,$cells }
            }
            if ($null -ne $headerRow) {
                [void]$sb.AppendLine('<div class="table-wrap"><table><thead><tr>')
                foreach ($c in $headerRow) { [void]$sb.AppendLine('<th>' + (Convert-Inline $c) + '</th>') }
                [void]$sb.AppendLine('</tr></thead><tbody>')
                foreach ($cells in $bodyRows) {
                    [void]$sb.AppendLine('<tr>')
                    foreach ($c in $cells) { [void]$sb.AppendLine('<td>' + (Convert-Inline $c) + '</td>') }
                    [void]$sb.AppendLine('</tr>')
                }
                [void]$sb.AppendLine('</tbody></table></div>')
            }
            continue
        }
        # 标题
        if ($line -match '^(#{1,6})\s+(.*)$') {
            $lv = $Matches[1].Length + 1
            if ($lv -gt 6) { $lv = 6 }
            [void]$sb.AppendLine("<h$lv>" + (Convert-Inline $Matches[2]) + "</h$lv>")
            $i++
            continue
        }
        # 分隔线
        if ($line -match '^\s*(-{3,}|\*{3,}|_{3,})\s*$') {
            [void]$sb.AppendLine('<hr>')
            $i++
            continue
        }
        # 引用
        if ($line -match '^>\s?(.*)$') {
            $collected = @()
            while ($i -lt $n -and $lines[$i] -match '^>\s?(.*)$') {
                $collected += $Matches[1]
                $i++
            }
            [void]$sb.AppendLine('<blockquote>' + (Convert-Inline ($collected -join '<br>')) + '</blockquote>')
            continue
        }
        # 无序列表
        if ($line -match '^\s*[-*+]\s+(.*)$') {
            [void]$sb.AppendLine('<ul>')
            while ($i -lt $n -and $lines[$i] -match '^\s*[-*+]\s+(.*)$') {
                [void]$sb.AppendLine('<li>' + (Convert-Inline $Matches[1]) + '</li>')
                $i++
            }
            [void]$sb.AppendLine('</ul>')
            continue
        }
        # 有序列表
        if ($line -match '^\s*\d+[\.、]\s+(.*)$') {
            [void]$sb.AppendLine('<ol>')
            while ($i -lt $n -and $lines[$i] -match '^\s*\d+[\.、]\s+(.*)$') {
                [void]$sb.AppendLine('<li>' + (Convert-Inline $Matches[1]) + '</li>')
                $i++
            }
            [void]$sb.AppendLine('</ol>')
            continue
        }
        # 空行
        if ($line -match '^\s*$') { $i++; continue }
        # 段落
        $para = @()
        while ($i -lt $n) {
            $l = $lines[$i]
            if ($l -match '^\s*$') { break }
            if ($l -match '^```|^(#{1,6})\s|^\s*\|.*\|\s*$|^\s*[-*+]\s+.*$|^\s*\d+[\.、]\s+.*$') { break }
            $para += $l
            $i++
        }
        [void]$sb.AppendLine('<p>' + (Convert-Inline ($para -join '<br>')) + '</p>')
    }
    return $sb.ToString()
}

function Get-LevelStr([double]$lv) {
    $n = [int][Math]::Round($lv)
    if ($n -lt 1) { $n = 1 }
    if ($n -gt 5) { $n = 5 }
    return ('★' * $n) + ('☆' * (5 - $n))
}

function Get-LevelLabel([double]$lv) {
    $n = [int][Math]::Round($lv)
    switch ($n) {
        1 { return '入门' }
        2 { return '简单' }
        3 { return '中等' }
        4 { return '较难' }
        5 { return '困难' }
        default { return '中等' }
    }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Utf8([string]$path, [string]$content) {
    [System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
}

# ============ 读取数据 ============
Write-Host 'reading data...'
$list = Get-Content "$rawDir\topic_list.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$props = @($list.PSObject.Properties)
$total = $props.Count
Write-Host "topics: $total"

$details = @{}
foreach ($p in $props) {
    $f = "$rawDir\answers\$($p.Name).json"
    if (Test-Path $f) {
        $details[$p.Name] = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json
    } else {
        Write-Host "MISSING $($p.Name)"
    }
}

$catCount = @{}
foreach ($t in $tags) { $catCount[$t] = 0 }
$catItems = @{}
foreach ($t in $tags) { $catItems[$t] = New-Object System.Collections.ArrayList }

$topicSeq = @()
$seq = 0
foreach ($p in $props) {
    $seq++
    $meta = $p.Value
    $detailTags = @($meta.tags | Where-Object { $_ -ne '全部' })
    $topicSeq += @{ n = $seq; key = $p.Name; title = $meta.title; tags = $detailTags }
    foreach ($t in $meta.tags) {
        if ($catCount.ContainsKey($t)) {
            $catCount[$t]++
            $catItems[$t].Add($p.Name) | Out-Null
        }
    }
}

function Get-FooterHtml {
    return @"
<footer class="site-footer"><div class="wrap"><p>前端面试题知识库 · 数据来源 <a href="https://fe.ecool.fun/topic-list" target="_blank" rel="noopener">前端面试题宝典</a> · 共 $total 题 · 2026-08-17 抓取</p></div></footer>
"@
}
