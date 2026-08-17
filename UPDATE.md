# 题库更新操作指引（给 AI 的提示脚本）

当用户说"更新题库"、"刷新题库"、"同步最新题目"时，按照本文件执行。

## 任务目标

将 https://fe.ecool.fun/topic-list（前端面试题宝典）的最新题目、答案重新抓取，并重新生成知识库网站（首页 + 分类页 + 题目详情页）。

知识库位置：`C:\Users\22695\workpalce\myself\前端面试题知识库`

## 执行步骤

### 第 1 步：检查登录凭证是否有效

先调用 API 验证 `_config\cookies.json` 中的登录凭证（utoken 是 JWT，约 7 天过期）：

```powershell
$cfg = Get-Content 'C:\Users\22695\workpalce\myself\前端面试题知识库\_config\cookies.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.Cookies.Add((New-Object System.Net.Cookie('utoken', $cfg.utoken, '/', 'fe.ecool.fun'))) | Out-Null
$session.Cookies.Add((New-Object System.Net.Cookie('utoken.sig', $cfg.'utoken.sig', '/', 'fe.ecool.fun'))) | Out-Null
$session.Cookies.Add((New-Object System.Net.Cookie('csrfToken', $cfg.csrfToken, '/', 'fe.ecool.fun'))) | Out-Null
$headers = @{'User-Agent'='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'; 'Referer'='https://fe.ecool.fun/topic-list'}
$r = Invoke-RestMethod -Uri 'https://fe.ecool.fun/api/exercise/list?vid=9&exerciseCate=0&pageNum=1&pageSize=1&ignoreMaster=1&orderBy=default&order=desc' -WebSession $session -Headers $headers -TimeoutSec 20
$r.code   # 0 表示有效
```

- 若返回 `code=0` 且有数据 → 凭证有效，继续第 2 步。
- 若请求失败或 code≠0 → 凭证失效，按下方"更新登录凭证"处理后再继续。

### 第 2 步：执行一键更新脚本

```powershell
& 'C:\Users\22695\workpalce\myself\前端面试题知识库\update.ps1'
```

- 脚本为长任务（抓取约 400 个列表请求 + 1900 个详情请求 + 生成 1900 个页面），预计 **15-25 分钟**，应以后台非阻塞方式运行，期间定期检查输出。
- 脚本会自动依次执行：校验凭证 → 抓列表 → 抓详情 → 生成网站 → 输出验证结果。

### 第 3 步：核对验证结果

脚本结束时输出验证信息，需确认：

| 检查项 | 期望值 | 说明 |
| --- | --- | --- |
| 题目总数 | 与网站 totalCount 一致（当前约 1900+，随时间增长） | 对比本次与上次的数量，了解增量 |
| 详情 JSON 数 | = 题目总数 | 若小于总数说明有抓取失败 |
| 分类页 | 25 个 | 网站当前有 25 个具体分类（不含"全部"） |
| 详情页 | = 题目总数 | |
| 未归类提示 | 无 | 若有提示说明网站新增了分类，见下方"新分类处理" |

### 第 4 步：向用户汇报

用中文简要汇报：本次更新后的题目总数、较上次新增/删除的数量、是否有异常。无需逐条罗列题目。

## 更新登录凭证（cookie 失效时）

1. 请用户用浏览器打开并登录 https://fe.ecool.fun/topic-list（登录后点击任意题目应能看到"查看答案"）。
2. 打开开发者工具（F12）→ Application（应用）→ Cookies → `https://fe.ecool.fun`，复制三个值：
   - `utoken`
   - `utoken.sig`
   - `csrfToken`
3. 更新 `_config\cookies.json` 中的对应字段（保留 `updatedAt` 字段并改为当天日期）。
4. 重新执行第 1、2 步。

## 脚本说明（scripts/ 目录）

| 脚本 | 职责 |
| --- | --- |
| `update.ps1`（知识库根目录） | 一键更新入口：校验凭证 → 串行执行全部步骤 → 输出验证结果 |
| `scripts/fetch_list.ps1` | 抓取 26 个分类（含"全部"）的题目列表，生成 `_raw\topic_list.json`（含 exerciseKey、标题、难度、分类标签） |
| `scripts/fetch_details.ps1` | 按列表逐个调详情 API 抓取完整答案，存 `_raw\answers\<exerciseKey>.json`（已有文件自动跳过，支持断点续传） |
| `scripts/kb_common.ps1` | 公共模块：路径配置、Markdown→HTML 转换器、难度/分级工具、数据加载 |
| `scripts/gen_assets.ps1` | 生成 `assets/`（样式、脚本、搜索索引）、`index.html` 首页、`categories/` 25 个分类列表页 |
| `scripts/gen_details.ps1` | 生成 `questions/` 题目详情页（每题一页，含答案、选项高亮、上下题导航） |

所有脚本从 `_config\cookies.json` 读取登录凭证，不硬编码。

## 注意事项

- **编码**：所有 .ps1 脚本必须为 **UTF-8 with BOM**（PowerShell 5.1 会将无 BOM 的 UTF-8 按 ANSI 解析导致中文乱码）。若用编辑器修改过脚本，请确认编码。
- **不要手工修改生成文件**：`index.html`、`categories/`、`questions/`、`assets/`、`_raw/` 均为脚本生成，改版后会被覆盖。
- **新分类处理**：网站若新增分类，需在 `scripts/fetch_list.ps1` 的 `$tags` 数组补充新分类的 `tagId` 和名称（tagId 通过网站点击分类标签观察 URL 参数获取），并在 `scripts/kb_common.ps1` 的 `$tags` 数组同步添加。update.ps1 的验证环节会提示是否存在未归类题目。
- **详情抓取支持断点续传**：中途失败重跑即可，已下载的题目会自动跳过。
- 本机没有 Node.js / Python，一切处理均基于 PowerShell 5.1。
