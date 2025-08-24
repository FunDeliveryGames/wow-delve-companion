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
-addonsFolderPtr "C:\\Program Files\\World of Warcraft\\_xptr_\\Interface\\AddOns"
#>
param (
    [string]$yamlPath,
    [string]$addonsFolderRetail,
    [string]$addonsFolderPtr,
    [string]$addonsFolderXptr
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

# ======= READ & PARSE YAML =======
# Use YAML file to make a list of ignored folders and files
$yamlContent = Get-Content $yamlPath

$packageAs = ""
$ignoreDirs = @()
$ignoreFiles = @()

foreach ($line in $yamlContent) {
    $trimmed = $line.Trim()
    if ($trimmed -like "package-as:*") {
        $packageAs = $trimmed.Substring($trimmed.IndexOf(":") + 1).Trim()
    }
    elseif ($trimmed -like "-*") {
        $item = $trimmed.TrimStart("-").Trim()

        if ($item.EndsWith(" #folder")) {
            $item = $item.Split('#')[0].Trim()
            $ignoreDirs += $item
            # Write-Output "Ignore folder: " $item
        }
        else {
            $ignoreFiles += $item
            # Write-Output "Ignore file: " $item
        }
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

    $xdParams = ""
    if ($ignoreDirs.Count -gt 0) {
        $quotedDirs = $ignoreDirs | ForEach-Object {
            if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ }
        }
        $xdParams = "/XD " + ($quotedDirs -join " ")
    }

    $xfParams = ""
    if ($ignoreFiles.Count -gt 0) {
        $xfParams = "/XF " + ($ignoreFiles -join " ")
    }

    $robocopyCmd = "robocopy `"$sourcePath`" `"$targetPath`" /E $xdParams $xfParams"
    Invoke-Expression $robocopyCmd
}