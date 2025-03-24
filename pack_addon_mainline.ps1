# Script args
param (
    # Path to YAML configuration file
    [string]$yamlPath,
    # Path to WoW AddOns folder    
    [string]$addonsLocation
)

if ([string]::IsNullOrEmpty($addonsLocation)) {
    Write-Error "Addons folder is not provided. Check script args."
    exit 1
}
if ([string]::IsNullOrEmpty($yamlPath)) {
    Write-Error "YAML configuration is not provided. Check script args."
    exit 1
}
function Get-AddonVersion {
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

# Initialize variables
$packageAs = ""

foreach ($line in $yamlContent) {
    $trimmed = $line.Trim()
    if ($trimmed -like "package-as:*") {
        # Extract value after the colon and trim spaces
        $packageAs = $trimmed.Substring($trimmed.IndexOf(":") + 1).Trim()
    }
}

if ([string]::IsNullOrEmpty($packageAs)) {
    Write-Error "The YAML file must define a 'package-as' variable."
    exit 1
}

# ======= DETERMINE DIRECTORIES =======
$sourceDir = Join-Path $addonsLocation $packageAs
$targetDir = ".\releases"
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
Compress-Archive -Path $sourceDir -DestinationPath $zipFilePath -Force

Write-Output "Packaging complete. ZIP archive located at '$zipFilePath'."
