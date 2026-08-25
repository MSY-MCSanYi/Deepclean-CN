# 强制当前会话使用 UTF8 编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "SilentlyContinue"

# ==========================================
# 1. 界面标题 (V7)
# ==========================================
Clear-Host
Write-Host ""
Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
Write-Host " |                                                          |" -ForegroundColor Cyan
Write-Host " |          >>> WINDOWS 深度清理引擎 V7 <<<                 |" -ForegroundColor Green
Write-Host " |                                                          |" -ForegroundColor Cyan
Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
Write-Host " |  作者: Lightspeed Sharing                                |" -ForegroundColor Yellow
Write-Host " |  GitHub: https://github.com/Cotton059/Light-Help         |" -ForegroundColor Yellow
Write-Host " |  模式: 实时矩阵扫描 (精准计数模式)                       |" -ForegroundColor DarkGray
Write-Host " +----------------------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# 2. 扫描前确认
# ==========================================
Write-Host "[?] 软件将遍历所有目录以定位垃圾文件。" -ForegroundColor Cyan
$scanConsent = Read-Host ">>> 准备好启动大规模扫描程序了吗？ (默认: Y)"

if ($scanConsent -ne "" -and $scanConsent -notmatch "^[Yy]$") {
    Write-Host "`n[-] 用户已取消操作。" -ForegroundColor Red
    exit
}

# ==========================================
# 3. 权限检查
# ==========================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n[!] 警告: 未以管理员身份运行。" -ForegroundColor Red
    Write-Host "    系统级日志和 Temp 临时文件夹将被跳过。`n" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
}

# ==========================================
# 4. 实时瀑布流扫描 (精准计数引擎)
# ==========================================
Write-Host "`n[*] 正在初始化全量无限制扫描协议..." -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

$global:foundTargets = @()
$global:totalScanned = 0  # 计数器
$targetKeywords = "Temp|Cache|CrashDumps|LogFiles"
$baseScanPath = $env:USERPROFILE

# 用于实时输出和精准计数的自定义递归函数
function Invoke-RealTimeScan {
    param([string]$CurrentPath)
    try {
        $dirs = Get-ChildItem -Path $CurrentPath -Directory -Force -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            $global:totalScanned++  # 递增每个遍历到的目录
            $dirPath = $dir.FullName
            
            # 实时打印每个目录
            Write-Host " [扫描] $dirPath" -ForegroundColor DarkGray
            
            # 锁定目标时高亮显示
            if ($dir.Name -match $targetKeywords) {
                Write-Host " [>>>] 已锁定目标: $dirPath" -ForegroundColor Yellow
                $global:foundTargets += $dir
            }
            
            # 递归深入
            Invoke-RealTimeScan -CurrentPath $dirPath
        }
    } catch {}
}

# 开始大规模扫描
Invoke-RealTimeScan -CurrentPath $baseScanPath

# 扫描系统级路径
$systemJunkPaths = @(
    "$env:TEMP",
    "$env:WINDIR\Temp",
    "$env:WINDIR\Prefetch",
    "$env:WINDIR\SoftwareDistribution\Download"
)

foreach ($sysPath in $systemJunkPaths) {
    $global:totalScanned++  # 计入系统路径
    if (Test-Path $sysPath) {
        $dirItem = Get-Item $sysPath
        Write-Host " [>>>] 系统目标: $($dirItem.FullName)" -ForegroundColor Red
        $global:foundTargets += $dirItem
    }
}

Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray

# ==========================================
# 5. 执行确认
# ==========================================
if ($global:foundTargets.Count -eq 0) {
    Write-Host "`n[V] 恭喜！未找到垃圾目录。" -ForegroundColor Green
    Read-Host "`n按回车键退出..."
    exit
}

# 格式化大数字（例如：45,123）
$formattedTotal = "{0:N0}" -f $global:totalScanned

Write-Host "`n[*] 分析完成！已扫描 $formattedTotal 个路径，锁定 $($global:foundTargets.Count) 个垃圾区域。" -ForegroundColor Green
$confirm = Read-Host ">>> 是否立即授权深度清理？[Y/n] (默认: Y)"

if ($confirm -ne "" -and $confirm -notmatch "^[Yy]$") {
    Write-Host "`n[-] 清理已取消，未删除任何文件。" -ForegroundColor DarkGray
    exit
}

# ==========================================
# 6. 粉碎清理进程
# ==========================================
Write-Host "`n[*] 正在粉碎文件..." -ForegroundColor Cyan
$totalFreedBytes = 0

foreach ($folder in $global:foundTargets) {
    $folderPath = $folder.FullName
    Write-Host "  -> 正在清理: $folderPath" -ForegroundColor DarkGray

    $size = (Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if ($null -ne $size) { $totalFreedBytes += $size }

    Remove-Item -Path "$folderPath\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# ==========================================
# 7. 最终报告
# ==========================================
$freedMB = [math]::Round($totalFreedBytes / 1MB, 2)
$freedGB = [math]::Round($totalFreedBytes / 1GB, 2)

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host " [OK] 任务完成！" -ForegroundColor Green

if ($totalFreedBytes -gt 1GB) {
    Write-Host " [!] 已释放: $freedGB GB 磁盘空间。" -ForegroundColor Yellow
} elseif ($freedMB -gt 0) {
    Write-Host " [!] 已释放: $freedMB MB 磁盘空间。" -ForegroundColor Yellow
} else {
    Write-Host " [V] 系统已处于最佳优化状态。" -ForegroundColor Yellow
}

Write-Host ""
Write-Host " 支持: Lightspeed Sharing (YT)" -ForegroundColor Magenta
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "按回车键关闭..."