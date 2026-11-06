<#
.SYNOPSIS
    Reads a CSV file with a "Path" column and sorts hierarchically so that
    each child appears directly after its parent.

.DESCRIPTION
    This script:
    - Imports the CSV file.
    - Validates the "Path" column.
    - Splits each path into segments.
    - Sorts by hierarchy so that children follow their parent immediately.

.PARAMETER CsvFile
    Path to the CSV file containing the "Path" column.

.EXAMPLE
    .\Sort-Hierarchical.ps1 -CsvFile "directories.csv"
#>
$FilePath = "C:\Users\Nathan.Sanders\Documents\DS Folder"
$CsvFiles = (Get-ChildItem -Path "$FilePath\*.csv").FullName
foreach ($CsvFile in $CsvFiles) {
    try {
        if (-not (Test-Path -Path $CsvFile -PathType Leaf)) {
            throw "CSV file '$CsvFile' not found."
        }

        $csvData = Import-Csv -Path $CsvFile
        <#$csvData = ((Import-Csv -Path $CsvFile) -replace (".*\:\\",""))
        "Path" | Out-File -FilePath $CsvFile
        $csvData | Out-File -FilePath $CsvFile -Append}
        #>

        if (-not ($csvData | Get-Member -Name 'Path' -MemberType NoteProperty)) {
            throw "CSV file must contain a 'Path' column."
        }

        function Get-Segments($path) {
            # Change '\.' to '\\' if you are working with real directory paths
            return $path.Trim() -split '\.'
        }

        function Normalize-Segment($segment) {
            # Try to parse as integer; if fails, return lowercase text
            if ([int]::TryParse($segment, [ref]$null)) {
                return ,([int]$segment)  # numeric sort
            } else {
                return ,($segment.ToLower())  # text sort
            }
        }

        $sortedPaths = $csvData |
            Sort-Object -Property @{Expression = {
                $segments = Get-Segments $_.Path
                # Normalize each segment for mixed numeric/text sorting
                $segments | ForEach-Object { Normalize-Segment $_ }
            }
        }
        "Path" | Out-File -FilePath $CsvFile
        $sortedPaths | Out-File $CsvFile -Append
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

$CsvFiles = (Get-ChildItem -Path "$FilePath\*.csv").FullName
foreach ($CsvFile in $CsvFiles) {
    # Define file paths
    $inputFile  = $CsvFile   # Original CSV file
    $outputFile = $CsvFile  # New CSV file without rows 2,3,4

    try {
        # Import CSV as raw text to preserve exact row positions
        $lines = Get-Content -Path $inputFile -ErrorAction Stop

        if ($lines.Count -le 4) {
            Write-Host "The file has 4 or fewer lines. Nothing to remove." -ForegroundColor Yellow
            return
        }

        # Keep the header (line 0) and all lines after line 3
        $filteredLines = $lines[0] + "`n" + ($lines | Select-Object -Skip 4)
        foreach ($filteredLine in $filteredLines) {
            Out-File -FilePath $outputFile -Value $filteredLine -Encoding UTF8 -Append
        }
        # Save to new file
        Set-Content -Path $outputFile -Value $filteredLines -Encoding UTF8

        Write-Host "Rows 1, 2, and 3 removed successfully. Output saved to $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}


#Remove-Item -Path "$FilePath\*wlevels.csv"

# Define the root Path
$rootPath = "S:\Working Projects"
$normalizedRoot = $rootPath.TrimEnd('\')
$Files = Get-ChildItem -Path "$FilePath\*.csv"
foreach ($File in $Files) {
    $InputCsv = $File.FullName
    $OutputCsv = "$FilePath\$($File.BaseName)_wlevels.csv"

    # Import CSV
    try {
        $data = Import-Csv -Path $InputCsv -ErrorAction Stop
    } catch {
        Write-Error "Failed to read CSV file: $_"
        exit 1
    }

    # Check if "Path" column exists
    if (-not ($data | Get-Member -Name "Path" -MemberType NoteProperty)) {
        Write-Error "CSV must contain a 'Path' column."
        exit 1
    }

    # Process and preserve all columns
    $result = foreach ($row in $data) {
        # Safely get Path value (avoid null errors)
        $dirPath = if ($null -ne $row.Path) { $row.Path.Trim() } else { "" }
        $level = ""

        if ($dirPath -ne "") {
            # Normalize slashes
            $normalizedPath = $dirPath.TrimEnd('\')

            if ($normalizedPath -like "$normalizedRoot*") {
                $relativePath = $normalizedPath.Substring($normalizedRoot.Length).TrimStart('\')
                if ($relativePath -eq "") {
                    $level = 1
                } else {
                    $level = ($relativePath.Split('\').Count) + 1
                }
            } else {
                $level = "N/A"
            }
        }

        # Copy all original properties + add Level
        $props = @{}
        foreach ($prop in $row.PSObject.Properties) {
            $props[$prop.Name] = $prop.Value
        }
        $props["Level"] = $level

        [PSCustomObject]$props
    }

    # Export updated CSV
    try {
        $result | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        Write-Host "Updated CSV saved to: $OutputCsv"
    } catch {
        Write-Error "Failed to write output CSV: $_"
    }
}

#Remove-Item -Path "$FilePath\txt\*.txt"

# FolderTree.ps1
#ScriptVersion = "1.0"

$WLFiles = Get-ChildItem -Path "$FilePath\*wlevels.csv"
foreach ($WLFile in $WLFiles) {
    $File = $WLFile.FullName

    $OutFile = "C:\Users\Nathan.Sanders\Documents\DS Folder\txt\$($WLFile.BaseName).txt"

    "Folder structure preview:" | Out-File $OutFile -Force
    "" | Out-File $OutFile -Append -Force

    # Import CSV with Name (folder name) and Level (1 = root, 2 = child of last level-1, etc.)
    $Folders = Import-Csv $File -Delimiter ","

    # ─── FOLDER TREE PREVIEW ────────────────────────────────────────────────────
    function Show-FolderTree {
        param([array]$FolderList)

        $total = $FolderList.Count
        for ($i = 0; $i -lt $total; $i++) {
            $name = ($FolderList[$i].Path -replace (".*\\",""))
            $level = [int]$FolderList[$i].Level

            if ([string]::IsNullOrWhiteSpace($name) -or $level -lt 1) { continue }

            # Determine if this item has a sibling at the same level
            $hasNextSibling = $false
            for ($j = $i + 1; $j -lt $total; $j++) {
                $nextLevel = [int]$FolderList[$j].Level
                if ($nextLevel -lt $level) { break }
                if ($nextLevel -eq $level) { $hasNextSibling = $true; break }
            }

            # Build prefix for ancestors
            $prefix = ""
            for ($lvl = 1; $lvl -lt $level; $lvl++) {
                $ancestorHasSibling = $false
                for ($k = $lvl; $k -lt $total; $k++) {
                    $nextAncestorLevel = [int]$FolderList[$k].Level
                    if ($nextAncestorLevel -lt $lvl) { break }
                    if ($nextAncestorLevel -eq $lvl) { $ancestorHasSibling = $true; break }
                }
                if ($ancestorHasSibling) { $prefix += "│   " } else { $prefix += "    " }
            }

            # Draw branch symbol
            if ($hasNextSibling) { $branch = "├── " } else { $branch = "└── " }

            "$prefix$branch$name" | Out-File $OutFile -Append -Force
        }
    }

    # ─── BUILD FOLDERS (optional) ──────────────────────────────────────────────
    function Build-Folders {
        param([string]$RootPath)

        $Folders = Import-Csv $File -Delimiter ","
        $total = $Folders.Count
        for ($i = 0; $i -lt $total; $i++) {
            $name = $Folders[$i].Name
            $level = [int]$Folders[$i].Level
            if ([string]::IsNullOrWhiteSpace($name) -or $level -lt 1) { continue }

            $path = Join-Path $RootPath $name
            if (-not (Test-Path $path)) {
                New-Item -ItemType Directory -Path $path -Force
            }
        }
    }

    # ─── RUN ───────────────────────────────────────────────────────────────────
    Show-FolderTree $Folders
    $Folders | Out-File $OutFile -Append
}
# Optional: Build actual folders in a root directory
# Build-Folders "C:\MyFolderStructure"