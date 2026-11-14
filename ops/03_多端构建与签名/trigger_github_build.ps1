param(
    [string]$RemoteUrl = "",
    [string]$Tag = "seahorse-v1.0.0",
    [ValidateSet("all", "windows", "macos", "ios", "harmonyos", "android")]
    [string]$Platform = "all",
    [switch]$DispatchOnly,
    [switch]$ForceDispatch,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$isHeadless = $NonInteractive.IsPresent -or ($env:SEAHORSE_NON_INTERACTIVE -eq '1') -or (-not [string]::IsNullOrEmpty($env:CI)) -or [Console]::IsInputRedirected
if ($isHeadless) {
    $env:GIT_TERMINAL_PROMPT = "0"
    $env:GCM_INTERACTIVE = "never"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StandaloneCandidate = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
if (Test-Path (Join-Path $StandaloneCandidate ".git")) {
    $RepoRoot = $StandaloneCandidate
} else {
    $RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
}
$WorkflowFile = "build-seahorse-clients.yml"

function Invoke-Git {
    param([string[]]$ArgsList, [switch]$AllowFailure)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & git -C $RepoRoot @ArgsList 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ((-not $AllowFailure) -and ($exitCode -ne 0)) {
        $joined = ($output | Out-String).Trim()
        throw "git $($ArgsList -join ' ') 执行失败 (exit=$exitCode): $joined"
    }
    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output   = ($output | Out-String).Trim()
    }
}

function Parse-GitHubOwnerRepo([string]$Url) {
    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
    $clean = $Url.Trim()
    if ($clean -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/\s]+?)(?:\.git)?/?$') {
        return [PSCustomObject]@{
            Owner = $Matches['owner']
            Repo  = $Matches['repo']
        }
    }
    return $null
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  海马智慧门店 (Seahorse) — GitHub 一键推送与五端云构建触发工具" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  仓库根目录 : $RepoRoot"
Write-Host "  目标标签   : $Tag"
Write-Host "  构建平台   : $Platform"
Write-Host "  仅触发构建 : $($DispatchOnly.IsPresent)"
Write-Host "----------------------------------------------------------------------"

$gitCheck = Get-Command "git" -ErrorAction SilentlyContinue
if (-not $gitCheck) {
    throw "未检测到 git 命令行工具，请先安装 Git 并加入系统 PATH。"
}

# 1. 检查或配置 origin 远程仓库
$remoteRes = Invoke-Git -ArgsList @("remote", "get-url", "origin") -AllowFailure
$originUrl = ""

if ($remoteRes.ExitCode -eq 0 -and (-not [string]::IsNullOrWhiteSpace($remoteRes.Output))) {
    $originUrl = $remoteRes.Output
    if ((-not [string]::IsNullOrWhiteSpace($RemoteUrl)) -and ($RemoteUrl.Trim() -ne $originUrl)) {
        Write-Host "[Remote] 更新现有 origin 远程地址 -> $($RemoteUrl.Trim())" -ForegroundColor Yellow
        Invoke-Git -ArgsList @("remote", "set-url", "origin", $RemoteUrl.Trim()) | Out-Null
        $originUrl = $RemoteUrl.Trim()
    } else {
        Write-Host "[Remote] 已检测到 origin -> $originUrl" -ForegroundColor Green
    }
} else {
    if (-not [string]::IsNullOrWhiteSpace($RemoteUrl)) {
        $originUrl = $RemoteUrl.Trim()
        Write-Host "[Remote] 正在绑定 origin -> $originUrl" -ForegroundColor Yellow
        Invoke-Git -ArgsList @("remote", "add", "origin", $originUrl) | Out-Null
    } elseif (-not $isHeadless) {
        Write-Host "[Remote] 当前仓库尚未配置 origin 远程地址。" -ForegroundColor Yellow
        $promptedUrl = Read-Host "请输入 GitHub 仓库地址 (例如 https://github.com/owner/repo.git)"
        if ([string]::IsNullOrWhiteSpace($promptedUrl)) {
            Write-Host "[提示] 未输入仓库地址，已取消推送。准备好仓库后可执行：" -ForegroundColor Yellow
            Write-Host "  git remote add origin https://github.com/<owner>/<repo>.git"
            Write-Host "  git push -u origin HEAD && git push origin $Tag"
            exit 1
        }
        $originUrl = $promptedUrl.Trim()
        Invoke-Git -ArgsList @("remote", "add", "origin", $originUrl) | Out-Null
        Write-Host "[Remote] 已绑定 origin -> $originUrl" -ForegroundColor Green
    } else {
        Write-Host "[提示] 当前仓库尚未配置 origin 远程仓库（非交互模式）。请执行以下两行命令完成绑定与推送：" -ForegroundColor Yellow
        Write-Host "  git -C `"$RepoRoot`" remote add origin https://github.com/<owner>/<repo>.git" -ForegroundColor Cyan
        Write-Host "  git -C `"$RepoRoot`" push -u origin HEAD && git -C `"$RepoRoot`" push origin $Tag" -ForegroundColor Cyan
        exit 1
    }
}

$branchRes = Invoke-Git -ArgsList @("rev-parse", "--abbrev-ref", "HEAD")
$currentBranch = if ([string]::IsNullOrWhiteSpace($branchRes.Output) -or $branchRes.Output -eq "HEAD") { "main" } else { $branchRes.Output }

# 2. 推送当前分支与版本 Tag（除非指定 -DispatchOnly）
$tagTriggeredPush = $false
if (-not $DispatchOnly.IsPresent) {
    $tagCheck = Invoke-Git -ArgsList @("rev-parse", "-q", "--verify", "refs/tags/$Tag") -AllowFailure
    if ($tagCheck.ExitCode -ne 0) {
        Write-Host "[Git] 本地尚未创建标签 $Tag，正在基于当前 HEAD 创建附注标签..." -ForegroundColor Yellow
        Invoke-Git -ArgsList @("tag", "-a", $Tag, "-m", "Release $Tag - Seahorse Smart Store Multi-Platform v1.0.0") | Out-Null
    }

    Write-Host "[Git] 正在推送分支 $currentBranch 至 origin..." -ForegroundColor Cyan
    $pushBranchRes = Invoke-Git -ArgsList @("push", "-u", "origin", "HEAD")
    if ($pushBranchRes.Output) { Write-Host "  $($pushBranchRes.Output)" }

    Write-Host "[Git] 正在推送标签 $Tag 至 origin..." -ForegroundColor Cyan
    $pushTagRes = Invoke-Git -ArgsList @("push", "origin", $Tag)
    if ($pushTagRes.Output) { Write-Host "  $($pushTagRes.Output)" }

    if ($pushTagRes.Output -notmatch "Everything up-to-date") {
        $tagTriggeredPush = $true
        Write-Host "[Git] 标签 $Tag 已推送到远端（将自动触发五端构建与 GitHub Release 发布流水线）。" -ForegroundColor Green
    } else {
        Write-Host "[Git] 远端标签 $Tag 已是最新状态。" -ForegroundColor Yellow
    }
}

# 3. 解析 GitHub {owner}/{repo} 并支持通过 GITHUB_TOKEN REST API 或 gh CLI 触发 workflow_dispatch + 输出实时运行链接
$ghRepo = Parse-GitHubOwnerRepo -Url $originUrl
if (-not $ghRepo) {
    Write-Host "[完成] 代码与标签推送完毕（非 github.com 标准地址，跳过 GitHub Actions REST API 触发）。" -ForegroundColor Green
    exit 0
}

$owner = $ghRepo.Owner
$repo = $ghRepo.Repo
$workflowPageUrl = "https://github.com/$owner/$repo/actions/workflows/$WorkflowFile"
$shouldDispatch = $DispatchOnly.IsPresent -or $ForceDispatch.IsPresent -or ($Platform -ne "all") -or (-not $tagTriggeredPush)

$hasToken = -not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)
$ghCli = Get-Command "gh" -ErrorAction SilentlyContinue
$hasGhAuth = $false
if ((-not $hasToken) -and $ghCli) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & gh auth status 1>$null 2>$null
    $hasGhAuth = ($LASTEXITCODE -eq 0)
    $ErrorActionPreference = $prevEap
}

if ($shouldDispatch) {
    if ($hasToken) {
        Write-Host "[Actions] 正在通过 GitHub REST API 触发 workflow_dispatch ($WorkflowFile, ref=$currentBranch, platform=$Platform)..." -ForegroundColor Cyan
        $dispatchUri = "https://api.github.com/repos/$owner/$repo/actions/workflows/$WorkflowFile/dispatches"
        $headers = @{
            "Authorization"        = "Bearer $($env:GITHUB_TOKEN.Trim())"
            "Accept"               = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
            "User-Agent"           = "Seahorse-Build-Trigger"
        }
        $bodyJson = @{
            ref    = $currentBranch
            inputs = @{
                platform = $Platform
            }
        } | ConvertTo-Json -Depth 5

        Invoke-RestMethod -Method Post -Uri $dispatchUri -Headers $headers -ContentType "application/json; charset=utf-8" -Body $bodyJson | Out-Null
        Write-Host "[Actions] workflow_dispatch 已成功提交！" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } elseif ($hasGhAuth) {
        Write-Host "[Actions] 正在通过 GitHub CLI (gh) 触发 workflow_dispatch ($WorkflowFile, ref=$currentBranch, platform=$Platform)..." -ForegroundColor Cyan
        & gh workflow run $WorkflowFile --repo "$owner/$repo" --ref $currentBranch -f "platform=$Platform"
        if ($LASTEXITCODE -ne 0) {
            throw "gh workflow run 触发失败 (exit=$LASTEXITCODE)"
        }
        Write-Host "[Actions] workflow_dispatch 已通过 gh CLI 成功提交！" -ForegroundColor Green
        Start-Sleep -Seconds 3
    } else {
        if ($DispatchOnly.IsPresent) {
            Write-Host "[提示] 指定了 -DispatchOnly，但当前环境未检测到 GITHUB_TOKEN 环境变量或已登录的 gh CLI。" -ForegroundColor Yellow
            Write-Host "  请设置 `$env:GITHUB_TOKEN = '<your_pat_with_workflow_scope>'` 后重试，或直接打开网页手动点击 Run workflow："
            Write-Host "  $workflowPageUrl" -ForegroundColor Cyan
            exit 1
        }
        Write-Host "[提示] 未配置 GITHUB_TOKEN 或 gh CLI，跳过主动 REST dispatch（可在浏览器查看流水线状态）。" -ForegroundColor Yellow
    }
}

# 4. 查询并输出最新的 GitHub Actions 实时构建 URL
$liveRunUrl = ""
if ($hasToken) {
    try {
        $runsUri = "https://api.github.com/repos/$owner/$repo/actions/workflows/$WorkflowFile/runs?per_page=1"
        $headers = @{
            "Authorization"        = "Bearer $($env:GITHUB_TOKEN.Trim())"
            "Accept"               = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
            "User-Agent"           = "Seahorse-Build-Trigger"
        }
        $runsResp = Invoke-RestMethod -Method Get -Uri $runsUri -Headers $headers
        if ($runsResp -and $runsResp.workflow_runs -and $runsResp.workflow_runs.Count -gt 0) {
            $liveRunUrl = $runsResp.workflow_runs[0].html_url
        }
    } catch {
        # 忽略只读查询异常，回退打印工作流主页 URL
    }
} elseif ($hasGhAuth) {
    try {
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $ghUrlOut = & gh run list --repo "$owner/$repo" --workflow $WorkflowFile --limit 1 --json url --jq ".[0].url" 2>$null
        $ErrorActionPreference = $prevEap
        if (-not [string]::IsNullOrWhiteSpace($ghUrlOut)) {
            $liveRunUrl = ($ghUrlOut | Out-String).Trim()
        }
    } catch {
    }
}

Write-Host "======================================================================" -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($liveRunUrl)) {
    Write-Host "  GitHub Actions 实时构建运行页 : $liveRunUrl" -ForegroundColor Green
} else {
    Write-Host "  GitHub Actions 工作流监控主页 : $workflowPageUrl" -ForegroundColor Green
}
Write-Host "  GitHub Releases 发行包下载页  : https://github.com/$owner/$repo/releases/tag/$Tag" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green
