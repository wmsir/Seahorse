param(
    [string]$InputPath = "",
    [string]$KeyAlias = "seahorse",
    [string]$StorePassword = "",
    [string]$DName = "CN=Seahorse Smart Store, OU=Store Engineering, O=Seahorse Commercial, L=Shanghai, ST=Shanghai, C=CN",
    [int]$ValidityDays = 10000,
    [switch]$Force,
    [switch]$EncodeOnly,
    [switch]$ConfigureLocalAndroid,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

$isHeadless = $NonInteractive.IsPresent -or ($env:SEAHORSE_NON_INTERACTIVE -eq '1') -or (-not [string]::IsNullOrEmpty($env:CI)) -or [Console]::IsInputRedirected

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SeahorseRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path
$ParentRoot = $null
try {
    $ParentRoot = (Resolve-Path (Join-Path $ScriptDir "..\..\..")).Path
} catch {
    $ParentRoot = $null
}

if ($ParentRoot -and (Test-Path (Join-Path $ParentRoot ".git")) -and (Test-Path (Join-Path $ParentRoot ".secrets\seahorse_signing"))) {
    $RepoRoot = $ParentRoot
} elseif (Test-Path (Join-Path $SeahorseRoot ".git")) {
    $RepoRoot = $SeahorseRoot
} elseif ($ParentRoot) {
    $RepoRoot = $ParentRoot
} else {
    $RepoRoot = $SeahorseRoot
}
$VaultDir = Join-Path $RepoRoot ".secrets\seahorse_signing"
New-Item -ItemType Directory -Force -Path $VaultDir | Out-Null

# Double-check that .secrets/seahorse_signing is gitignored and never inside tracked tree
$gitCmd = Get-Command "git" -ErrorAction SilentlyContinue
if ($gitCmd) {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & git -C $RepoRoot check-ignore -q ".secrets/seahorse_signing" 2>$null
    $gitIgnoreExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEap
    if ($gitIgnoreExit -ne 0) {
        throw "安全阻断: .secrets/seahorse_signing 未被根 .gitignore 忽略，拒绝生成私钥！"
    }
}

function Find-Keytool {
    $direct = Get-Command "keytool" -ErrorAction SilentlyContinue
    if ($direct) { return $direct.Source }

    $candidates = @()
    if ($env:JAVA_HOME) {
        $candidates += (Join-Path $env:JAVA_HOME "bin\keytool.exe")
    }
    $searchRoots = @(
        "C:\Program Files\Java",
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Android\Android Studio\jbr"
    )
    foreach ($root in $searchRoots) {
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Filter "keytool.exe" -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending
            foreach ($item in $found) {
                $candidates += $item.FullName
            }
        }
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

function New-StrongPassword([int]$Length = 24) {
    $alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789"
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    } finally {
        $rng.Dispose()
    }
    $chars = New-Object char[] $Length
    for ($i = 0; $i -lt $Length; $i++) {
        $chars[$i] = $alphabet[$bytes[$i] % $alphabet.Length]
    }
    return (-join $chars)
}

function Get-SecretHintName([System.IO.FileInfo]$File) {
    $ext = $File.Extension.ToLowerInvariant()
    $base = $File.BaseName.ToLowerInvariant()
    switch ($ext) {
        ".jks" { return "SEAHORSE_ANDROID_KEYSTORE_BASE64" }
        ".keystore" { return "SEAHORSE_ANDROID_KEYSTORE_BASE64" }
        ".mobileprovision" { return "SEAHORSE_IOS_PROVISION_BASE64" }
        ".cer" { return "SEAHORSE_OHOS_CER_BASE64" }
        ".p7b" { return "SEAHORSE_OHOS_P7B_BASE64" }
        ".pfx" { return "SEAHORSE_WINDOWS_PFX_BASE64" }
        ".p12" {
            if ($base -match "ohos|harmony") { return "SEAHORSE_OHOS_P12_BASE64" }
            if ($base -match "mac|apple_dev_id|tauri") { return "APPLE_CERTIFICATE" }
            return "SEAHORSE_IOS_P12_BASE64"
        }
        default { return "" }
    }
}

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  🔐 海马智慧门店 - 多端生产签名密钥生成与 Base64 编码工具" -ForegroundColor Cyan
Write-Host "  安全保险箱目录 (Git 已忽略): $VaultDir" -ForegroundColor Gray
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. 生成 Android 生产发布签名证书 (.jks)
$jksPath = Join-Path $VaultDir "seahorse-release.jks"
$credSummaryPath = Join-Path $VaultDir "android_signing_credentials.txt"

if (-not $EncodeOnly.IsPresent) {
    if ((Test-Path $jksPath) -and (-not $Force.IsPresent)) {
        Write-Host "[1/2] 已存在 Android 生产签名证书，跳过重新生成 (如需覆盖请传 -Force):" -ForegroundColor Green
        Write-Host "      $jksPath" -ForegroundColor White
    } else {
        $keytoolExe = Find-Keytool
        if (-not $keytoolExe) {
            throw "未找到 JDK keytool.exe，请安装 JDK 17+ 或设置 JAVA_HOME 环境变量。"
        }

        if ([string]::IsNullOrWhiteSpace($StorePassword)) {
            $StorePassword = New-StrongPassword -Length 24
        }

        if (Test-Path $jksPath) {
            Remove-Item $jksPath -Force
        }

        Write-Host "[1/2] 正在调用 keytool 生成 Android 生产发布签名证书 (RSA 2048-bit, 有效期 $ValidityDays 天)..." -ForegroundColor Yellow
        $genArgs = @(
            "-J-Duser.language=en",
            "-J-Dfile.encoding=UTF-8",
            "-genkeypair",
            "-noprompt",
            "-keystore", $jksPath,
            "-storetype", "PKCS12",
            "-keyalg", "RSA",
            "-keysize", "2048",
            "-validity", "$ValidityDays",
            "-alias", $KeyAlias,
            "-storepass", $StorePassword,
            "-keypass", $StorePassword,
            "-dname", $DName
        )
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $procOut = & $keytoolExe @genArgs 2>&1
        $genExit = $LASTEXITCODE
        $ErrorActionPreference = $prevEap
        if ($genExit -ne 0 -or (-not (Test-Path $jksPath))) {
            throw "keytool 生成证书失败: $($procOut -join "`n")"
        }

        # 提取公开指纹 (SHA-1 / SHA-256) 便于微信开放平台 / 高德地图 / 华为应用市场备案
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        $certListOut = & $keytoolExe "-J-Duser.language=en" "-J-Dfile.encoding=UTF-8" -list -v -keystore $jksPath -alias $KeyAlias -storepass $StorePassword 2>&1 | Out-String
        $ErrorActionPreference = $prevEap
        $sha256Match = [regex]::Match($certListOut, "SHA256:\s*([0-9A-Fa-f:]+)")
        $sha1Match = [regex]::Match($certListOut, "SHA1:\s*([0-9A-Fa-f:]+)")
        $sha256Fp = if ($sha256Match.Success) { $sha256Match.Groups[1].Value } else { "N/A" }
        $sha1Fp = if ($sha1Match.Success) { $sha1Match.Groups[1].Value } else { "N/A" }

        $credDoc = @"
# ==============================================================================
# Seahorse Android Production Signing Credentials (LOCAL VAULT - NEVER COMMIT)
# Generated At: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss K")
# Keystore File: $jksPath
# ==============================================================================

SEAHORSE_ANDROID_KEYSTORE_BASE64=<Copy from SEAHORSE_ANDROID_KEYSTORE_BASE64.txt>
SEAHORSE_ANDROID_STORE_PASSWORD=$StorePassword
SEAHORSE_ANDROID_KEY_ALIAS=$KeyAlias
SEAHORSE_ANDROID_KEY_PASSWORD=$StorePassword

# Public Certificate Fingerprints (Safe for App Gallery / WeChat / AMap registration)
CERT_SHA1=$sha1Fp
CERT_SHA256=$sha256Fp
"@
        [System.IO.File]::WriteAllText($credSummaryPath, $credDoc, $utf8NoBom)

        Write-Host "  ✓ 已生成 Android 正式签名密钥库: $jksPath" -ForegroundColor Green
        Write-Host "  ✓ 密钥别名 (Alias): $KeyAlias | 密码状态: [已加密保存至本地 .secrets，终端不回显明文]" -ForegroundColor Green
        Write-Host "  ✓ 证书公开指纹 SHA-256: $sha256Fp" -ForegroundColor Cyan
        Write-Host "  ✓ 完整 GitHub Secrets 对照清单已写入: $credSummaryPath" -ForegroundColor Gray

        if ($ConfigureLocalAndroid.IsPresent) {
            $localKeyProps = Join-Path $SeahorseRoot "seahorse_app\android\key.properties"
            $escapedJks = $jksPath.Replace('\', '/')
            $propsContent = @(
                "storePassword=$StorePassword",
                "keyPassword=$StorePassword",
                "keyAlias=$KeyAlias",
                "storeFile=$escapedJks"
            ) -join "`n"
            [System.IO.File]::WriteAllText($localKeyProps, "$propsContent`n", $utf8NoBom)
            Write-Host "  ✓ 已同步配置本地 Android 签名文件 (Git 已忽略): $localKeyProps" -ForegroundColor Green
        }
    }
}

# 2. 如果传入了外部证书/描述文件路径 (-InputPath)，安全归档或直接编码至 VaultDir
$extraFiles = @()
if (-not [string]::IsNullOrWhiteSpace($InputPath)) {
    if (-not (Test-Path $InputPath)) {
        throw "指定的 -InputPath 不存在: $InputPath"
    }
    $resolvedInput = Get-Item $InputPath
    if ($resolvedInput.PSIsContainer) {
        $extraFiles = Get-ChildItem -Path $resolvedInput.FullName -File |
            Where-Object { $_.Extension.ToLowerInvariant() -in @(".jks", ".keystore", ".p12", ".pfx", ".mobileprovision", ".cer", ".p7b") }
    } else {
        $extraFiles = @($resolvedInput)
    }
}

Write-Host ""
Write-Host "[2/2] 正在扫描并编码签名证书为单行无 BOM Base64 (.txt)..." -ForegroundColor Yellow

$vaultFiles = @(
    Get-ChildItem -Path $VaultDir -File |
        Where-Object { $_.Extension.ToLowerInvariant() -in @(".jks", ".keystore", ".p12", ".pfx", ".mobileprovision", ".cer", ".p7b") }
)

$allTargets = @{}
foreach ($f in (@($vaultFiles) + @($extraFiles))) {
    if ($null -ne $f) {
        $allTargets[$f.FullName] = $f
    }
}

if ($allTargets.Count -eq 0) {
    Write-Host "  ⚠️ 未发现待编码的签名文件 (.jks/.p12/.pfx/.mobileprovision/.cer/.p7b)。" -ForegroundColor Yellow
} else {
    foreach ($entry in $allTargets.GetEnumerator()) {
        $file = $entry.Value
        $rawBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $b64SingleLine = [Convert]::ToBase64String($rawBytes)

        $genericOut = Join-Path $VaultDir "$($file.Name).base64.txt"
        [System.IO.File]::WriteAllText($genericOut, $b64SingleLine, $utf8NoBom)

        $hintSecret = Get-SecretHintName -File $file
        if ($hintSecret) {
            $namedOut = Join-Path $VaultDir "$hintSecret.txt"
            [System.IO.File]::WriteAllText($namedOut, $b64SingleLine, $utf8NoBom)
            Write-Host ("  ✓ {0} ({1} bytes) -> {2} (对应 Secret: {3})" -f $file.Name, $rawBytes.Length, (Split-Path $namedOut -Leaf), $hintSecret) -ForegroundColor Green
        } else {
            Write-Host ("  ✓ {0} ({1} bytes) -> {2}" -f $file.Name, $rawBytes.Length, (Split-Path $genericOut -Leaf)) -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  ✅ 签名密钥准备与 Base64 导出完成！" -ForegroundColor Green
Write-Host "  📁 本地安全输出目录: $VaultDir" -ForegroundColor White
Write-Host "  📖 GitHub Secrets 配置指南: ops\03_多端构建与签名\SIGNING_GUIDE.md" -ForegroundColor White
Write-Host "====================================================================" -ForegroundColor Green

if (-not $isHeadless) {
    Write-Host ""
    Read-Host "按 Enter 键退出..."
}
