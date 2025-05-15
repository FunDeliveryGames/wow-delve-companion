<#
.SYNOPSIS
A script to pack addon into .zip archive.

.DESCRIPTION
The script copies all files of the addon from WoW AddOns folder and put them into .zip archive. The result archive is saved in the folder `./releases`.

.PARAMETER yamlPath
Path to YAML configuration file.

.PARAMETER addonsFolderRetail
Path to WoW AddOns folder.

.PARAMETER 7zipPath
Path to 7zip.exe.

.EXAMPLE
.\pack_addon_mainline.ps1
-yamlPath ".\\.pkgmeta"
-addonsFolderRetail "C:\\Program Files\\World of Warcraft\\_retail_\\Interface\\AddOns"
-7zipPath "C:\\Program Files\\7-Zip\\7z.exe"
#>
param (
    [string]$yamlPath,
    [string]$addonsFolderRetail,
    [string]$7zipPath
)

if ([string]::IsNullOrEmpty($addonsFolderRetail)) {
    Write-Error "Addons folder is not provided. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($yamlPath)) {
    Write-Error "YAML configuration is not provided. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($7zipPath)) {
    Write-Error "7zip path is not provided. Check script args."
    exit 1
}

function Get-AddonVersion {
    <#
    .SYNOPSIS
    A helper function to extract addon version from TOC file.

    .PARAMETER tocFilePath
    A description of what the 'Name' parameter is for.

    .EXAMPLE
    Get-AddonVersion -tocFilePath ".\DelveCompanion_Mainline.toc"

    .OUTPUTS
    String

    .INPUTS
    String
    #>
    param (
        [string]$tocFilePath
    )

    if (Test-Path $tocFilePath) {
        $tocContent = Get-Content -Path $tocFilePath
        foreach ($line in $tocContent) {
            if ($line -match "^##\s*Version:\s*(.+)$") {
                return $matches[1]
            }
        }
        Write-Error "Version information not found in $tocFilePath."
        exit 1
    }
    else {
        Write-Error "$tocFilePath does not exist."
        exit 1
    }
}

# ======= CONFIGURATION =======
# Path to the TOC file
$tocPath = ".\DelveCompanion_Mainline.toc"

# ======= READ & PARSE YAML =======
# Read the YAML file content
$yamlContent = Get-Content $yamlPath

$packageAs = ""
foreach ($line in $yamlContent) {
    $trimmed = $line.Trim()
    if ($trimmed -like "package-as:*") {
        $packageAs = $trimmed.Substring($trimmed.IndexOf(":") + 1).Trim()
    }
}

if ([string]::IsNullOrEmpty($packageAs)) {
    Write-Error "The YAML file must define a 'package-as' variable."
    exit 1
}

# ======= DETERMINE DIRECTORIES =======
$sourceDir = Join-Path $addonsFolderRetail $packageAs
$targetDir = ".\Releases"
if (-Not (Test-Path $targetDir)) {
    Write-Output "Creating release directory at '$targetDir'."
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

# ======= EXTRACT ADDON VERSION =======
$addonVersion = Get-AddonVersion -tocFilePath $tocPath

# ======= CREATE ZIP ARCHIVE =======
$zipFileName = "$packageAs`_$addonVersion.zip"
$zipFilePath = Join-Path $targetDir $zipFileName

if (Test-Path $zipFilePath) {
    Write-Output "Remove the existing archive..."
    Remove-Item $zipFilePath -Force
}

Write-Output "Creating ZIP archive at '$zipFilePath'."
& $7zipPath a -tzip $zipFilePath $sourceDir

Write-Output "Packaging complete. ZIP archive located at '$zipFilePath'."
