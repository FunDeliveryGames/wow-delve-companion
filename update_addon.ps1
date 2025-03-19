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

# ======= READ & PARSE YAML =======
# Read the YAML file content
$yamlContent = Get-Content $yamlPath

# Initialize variables
$packageAs = ""
$ignoreList = @()

foreach ($line in $yamlContent) {
    $trimmed = $line.Trim()
    if ($trimmed -like "package-as:*") {
        # Extract value after the colon and trim spaces
        $packageAs = $trimmed.Substring($trimmed.IndexOf(":") + 1).Trim()
    }
    elseif ($trimmed -like "-*") {
        # Extract ignore items (remove leading dash and trim)
        $item = $trimmed.TrimStart("-").Trim()
        $ignoreList += $item
    }
}

if ([string]::IsNullOrEmpty($packageAs)) {
    Write-Error "The YAML file must define a 'package-as' variable."
    exit 1
}

# ======= ADD YAML CONFIG TO IGNORE =======
# Ensure that the YAML configuration file itself is ignored during copying.
$yamlFileName = Split-Path $yamlPath -Leaf
$ignoreList += $yamlFileName

# ======= DETERMINE DIRECTORIES =======
# Source is the current directory (where this script and YAML file reside)
$sourceDir = Get-Location
$targetDir = Join-Path $addonsLocation $packageAs

# ======= PREPARE IGNORE LISTS =======
# Separate items into directories and files based on trailing backslash or slash.
$ignoreDirs = @()
$ignoreFiles = @()
foreach ($item in $ignoreList) {
    if ($item.EndsWith("\") -or $item.EndsWith("/")) {
        # Remove trailing slash/backslash for consistency
        $ignoreDirs += $item.TrimEnd("\", "/")
    }
    else {
        $ignoreFiles += $item
    }
}
# Also exclude the target folder (if it happens to be inside the source)
# $ignoreDirs += $packageAs

# ======= PREPARE TARGET FOLDER =======
# If target folder exists, remove it first
if (Test-Path $targetDir) {
    Write-Output "Target folder '$targetDir' exists. Deleting..."
    Remove-Item $targetDir -Recurse -Force
}

# Create a new target folder
Write-Output "Creating target folder '$targetDir'."
New-Item -ItemType Directory -Path $targetDir | Out-Null

# ======= COPY CONTENT WITH ROBOCOPY =======
# Build robocopy exclusion parameters:
#   /E  -> Copy all subdirectories (including empty ones)
#   /XD -> Exclude directories (separated by space)
#   /XF -> Exclude files (separated by space)
$sourcePath = $sourceDir.Path
$destinationPath = $targetDir

$xdParams = ""
if ($ignoreDirs.Count -gt 0) {
    $xdParams = "/XD " + ($ignoreDirs -join " ")
}

$xfParams = ""
if ($ignoreFiles.Count -gt 0) {
    $xfParams = "/XF " + ($ignoreFiles -join " ")
}

# Construct and display the robocopy command
$robocopyCmd = "robocopy `"$sourcePath`" `"$destinationPath`" /E $xdParams $xfParams"
Write-Output "Executing command:"
Write-Output $robocopyCmd

# Execute the robocopy command
Invoke-Expression $robocopyCmd
