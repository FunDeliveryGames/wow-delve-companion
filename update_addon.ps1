<#
.SYNOPSIS
A script to update addon files in WoW AddOns folder.

.DESCRIPTION
The script copies all required files according to YAML configuration file.

.PARAMETER yamlPath
Path to YAML configuration file.

.PARAMETER addonsFolderRetail
Path to WoW AddOns folder: _retail_.

.PARAMETER addonsFolderPtr
Path to WoW AddOns folder: _ptr_.

.PARAMETER addonsFolderXptr
Path to WoW AddOns folder: _xptr_.

.EXAMPLE
.\pack_addon_mainline.ps1
-yamlPath ".\\.pkgmeta"
-addonsFolderRetail "C:\\Program Files\\World of Warcraft\\_retail_\\Interface\\AddOns"
-addonsFolderPtr "C:\\Program Files\\World of Warcraft\\_ptr_\\Interface\\AddOns"
-addonsFolderXptr "C:\\Program Files\\World of Warcraft\\_xptr_\\Interface\\AddOns"
-addonsFolderBeta "C:\\Program Files\\World of Warcraft\\_beta_\\Interface\\AddOns"
#>
param (
    [string]$yamlPath,
    [string]$addonsFolderRetail,
    [string]$addonsFolderPtr,
    [string]$addonsFolderXptr,
    [string]$addonsFolderBeta
)

if ([string]::IsNullOrEmpty($yamlPath)) {
    Write-Error "YAML configuration is not found. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($addonsFolderRetail)) {
    Write-Error "_retail_ Addons folder is not found. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($addonsFolderPtr)) {
    Write-Error "_ptr_ Addons folder is not found. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($addonsFolderXptr)) {
    Write-Error "_xptr_ Addons folder is not found. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($addonsFolderBeta)) {
    Write-Error "_beta_ Addons folder is not found. Check script args."
    exit 1
}

# ======= READ & PARSE YAML =======
$yamlContent = Get-Content $yamlPath

$packageAs = ""
$ignoreDirs = @()
$ignoreFiles = @()
$inIgnore = $false

foreach ($line in $yamlContent) {
    $trimmed = $line.Trim()

    if ($trimmed -like 'package-as:*') {
        $packageAs = ($trimmed -split ':', 2)[1].Trim()
        continue
    }

    if ($trimmed -eq 'ignore:') {
        $inIgnore = $true
        continue
    }

    if (-not $inIgnore -or -not $trimmed.StartsWith('-')) {
        continue
    }

    $item = $trimmed.TrimStart('-').Trim()
    $item = ($item -split '#', 2)[0].Trim()  # strip inline comments

    if ($line -match '#folder') {
        # Robocopy /XD only accepts directory NAMES, not paths
        $ignoreDirs += (Split-Path $item -Leaf)
    }
    else {
        $ignoreFiles += $item
    }
}

if ([string]::IsNullOrEmpty($packageAs)) {
    Write-Error "The YAML file must define a 'package-as' variable."
    exit 1
}

# Ensure that the YAML configuration file itself is ignored during copying.
$yamlFileName = Split-Path $yamlPath -Leaf
$ignoreFiles += $yamlFileName

# ======= DETERMINE DIRECTORIES =======
$sourceDir = Get-Location
$targetDirs = @()
$targetDirs += Join-Path $addonsFolderRetail $packageAs
$targetDirs += Join-Path $addonsFolderPtr $packageAs
$targetDirs += Join-Path $addonsFolderXptr $packageAs
$targetDirs += Join-Path $addonsFolderBeta $packageAs

foreach ($targetPath in $targetDirs) {
    if (Test-Path $targetPath) {
        Write-Output "Target folder '$targetPath' exists. Deleting..."
        Remove-Item $targetPath -Recurse -Force
    }

    Write-Output "Creating target folder '$targetPath'."
    New-Item -ItemType Directory -Path $targetPath | Out-Null

    # ======= COPY CONTENT WITH ROBOCOPY =======
    # Build robocopy exclusion parameters:
    #   /E  -> Copy all subdirectories (including empty ones)
    #   /XD -> Exclude directories (separated by space)
    #   /XF -> Exclude files (separated by space)
    $sourcePath = $sourceDir.Path

    $robocopyArgs = @(
        "`"$sourcePath`""
        "`"$targetPath`""
        "/E"
    )

    if ($ignoreDirs.Count -gt 0) {
        $robocopyArgs += "/XD"
        $robocopyArgs += ($ignoreDirs | ForEach-Object { "`"$_`"" })
    }

    if ($ignoreFiles.Count -gt 0) {
        $robocopyArgs += "/XF"
        $robocopyArgs += ($ignoreFiles | ForEach-Object { "`"$_`"" })
    }

    $robocopyCmd = "robocopy " + ($robocopyArgs -join ' ')
    cmd /c $robocopyCmd
}