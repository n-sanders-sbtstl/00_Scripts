#$BasisOfTemplate = Get-ChildItem -Path "S:\Working Projects\2025 Projects\J25016 - Turkey Creek Pump Station Rehab_CDMSmith" -Recurse -Directory -Name
$TargetCSV = Get-ChildItem -Path "C:\Users\Nathan.Sanders\Documents\DS Folder\Structural.csv"
foreach ($CSV in $TargetCSV) {
    $BasisOfTemplate = Get-Content -Path $CSV
    $DirectoryList = $BasisOfTemplate | Sort-Object
    # Example: Replace this with your actual $Categories variable
    $Categories = ($DirectoryList -split "`r?`n")

    # Determine maximum depth in the folder structure
    $MaxDepth = ($Categories | ForEach-Object { ($_ -split '[\\]').Count } | Measure-Object -Maximum).Maximum

    # Ensure ImportExcel is available for CSV → XLSX conversion
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Host "Installing ImportExcel module..."
        Install-Module -Name ImportExcel -Scope CurrentUser -Force
    }

    # Build headers: "Name", then blank headers for levels, then "Description"
    #$Headers = @("Name")
    if ($MaxDepth -gt 1) {
        for ($i = 2; $i -le $MaxDepth; $i++) {
            #$Headers += ""   # Blank header instead of "Level#"
        }
    }
    #$Headers += "Description"

    # Prepare CSV file with headers
    $CsvFile = Join-Path $PWD "Categories.csv"
    Set-Content -Path $CsvFile -Value ($Headers -join ",")

    # Process each category path
    foreach ($path in $Categories) {
        # Split path into parts
        $parts = $path -split '[\\]'
        $depth = $parts.Count

        # Create an array of empty strings for hierarchy columns
        $row = @()
        for ($i = 1; $i -le $MaxDepth; $i++) {
            if ($i -eq $depth) {
                # Place folder name in the correct column
                $row += ($parts[-1] -replace ('"',''))
            } else {
                $row += ""
            }
        }

        # Add empty Description column
        $row += ""

        # Write row to CSV
        Add-Content -Path $CsvFile -Value ($row -join ",")
    }

    Write-Host "CSV file created: & $CsvFile"

    # Convert CSV to XLSX
    $XlsxFile = [System.IO.Path]::ChangeExtension($CsvFile, ".xlsx")
    Import-Csv -Path $CsvFile | Export-Excel -Path $XlsxFile -WorksheetName "Categories" -AutoSize -FreezeTopRow

    Write-Host "XLSX file created: $XlsxFile"
}

winget install --id Git.Git -e --source winget