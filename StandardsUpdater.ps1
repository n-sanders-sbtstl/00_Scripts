<#
.SYNOPSIS
    Recursively scans a directory, logs file details to a versioned CSV, 
    and compares it with the previous version to display change notifications.
#>
# Load required .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# --- CONFIGURATION ---
$TargetDirectory = "C:\Users\Nathan.Sanders\Documents\DS Folder"   # Change this to your directory
$CsvOutputFolder = "C:\Users\Nathan.Sanders\Documents"      # Where CSV versions will be saved

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Data Table MessageBox"
$form.Size = New-Object System.Drawing.Size(550, 320)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create the DataGridView
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Size = New-Object System.Drawing.Size(510, 220)
$grid.Location = New-Object System.Drawing.Point(10, 10)
$grid.AutoSizeColumnsMode = 'AllCells'
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.BackgroundColor = [System.Drawing.Color]::White
$grid.GridColor = [System.Drawing.Color]::Gray

$columns = @(
    @{ Header = "Object"; Width = 150 },
    @{ Header = "Change"; Width = 60 },
    @{ Header = "Name"; Width = 150 },
    @{ Header = "Path"; Width = 150 }
)

foreach ($colDef in $columns) {
    $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $col.HeaderText = $colDef.Header
    $col.Width = $colDef.Width
    $grid.Columns.Add($col)
}

# Ensure output directory exists
if (-not (Test-Path -Path $CsvOutputFolder)) {
    New-Item -ItemType Directory -Path $CsvOutputFolder | Out-Null
}

# --- STEP 1: Determine Next Version Number ---
$ExistingCsvs = Get-ChildItem -Path $CsvOutputFolder -Filter "file_scan_v*.csv" | Sort-Object {
    [int]($_.BaseName -replace '\D')
}

if ($ExistingCsvs.Count -eq 0) {
    $NextVersion = 1
} else {
    $LatestExisting = $ExistingCsvs[-1]
    $LatestVersionNum = [int]($LatestExisting.BaseName -replace '\D')
    $NextVersion = $LatestVersionNum + 1
}

$NewCsvPath = Join-Path $CsvOutputFolder "file_scan_v$NextVersion.csv"

# --- STEP 2: Collect Current Directory State ---
Write-Host "Scanning directory: $TargetDirectory..."
$CurrentScan = Get-ChildItem -Path $TargetDirectory -Recurse -File | Select-Object BaseName, FullName, LastWriteTime

# Write current scan to new CSV
$CurrentScan | Export-Csv -Path $NewCsvPath -NoTypeInformation
Write-Host "Saved current inventory to: $NewCsvPath"

# --- STEP 3: Compare Against Previous Version (if available) ---
if ($ExistingCsvs.Count -gt 0) {
    $PreviousCsvPath = $ExistingCsvs[-1].FullName
    Write-Host "Comparing against previous version: $PreviousCsvPath"
    
    $PreviousScan = Import-Csv -Path $PreviousCsvPath
    
    # Convert to hashtables/dictionaries for fast lookup by FullName and BaseName
    $PrevMap = @{}
    foreach ($row in $PreviousScan) {
        $PrevMap[$row.FullName] = $row
    }
    
    $CurrMap = @{}
    foreach ($row in $CurrentScan) {
        $CurrMap[$row.FullName] = $row
    }
    
    $Changes = @()

    # Check for New, Updated, or Moved files
    foreach ($curr in $CurrentScan) {
        $prev = $PrevMap[$curr.FullName]
        
        if (-not $prev) {
            # Check if it was moved (same BaseName or filename, different FullName/path)
            $movedMatch = $PreviousScan | Where-Object { $_.BaseName -eq $curr.BaseName -and $_.FullName -ne $curr.FullName } | Select-Object -First 1
            
            if ($movedMatch) {
                $Changes += [PSCustomObject]@{ Noun = "File"; Verb = "Moved"; Name = "$($curr.BaseName)"; Path = "moved from $($movedMatch.FullName) - to - $($curr.FullName)" }
            } else {
                $Changes += [PSCustomObject]@{ Noun = "File"; Verb = "New"; Name = "$($curr.BaseName)"; Path = "$($curr.FullName)" }
            }
        } else {
            # Existed previously; check if Updated (LastWriteTime is newer)
            $PrevTime = [datetime]$prev.LastWriteTime
            $CurrTime = [datetime]$curr.LastWriteTime
            
            if ($CurrTime -gt $PrevTime) {
                $Changes += [PSCustomObject]@{ Noun = "File"; Verb = "Updated"; Name = "$($curr.BaseName)"; Path = "$($curr.FullName)>" }
            }
        }
    }

    # Check for Removed files
    foreach ($prev in $PreviousScan) {
        if (-not $CurrMap[$prev.FullName]) {
            # Verify it wasn't just caught by the "Moved" check already
            $stillExistsSomewhere = $CurrentScan | Where-Object { $_.BaseName -eq $prev.BaseName }
            if (-not $stillExistsSomewhere) {
                $Changes += [PSCustomObject]@{ Noun = "File"; Verb = "Removed"; Name = "$($prev.BaseName)"; Path = "$($prev.FullName)>" }
            }
        }
    }

    # --- STEP 4: Display Popup Message Box if Changes Found ---
    if ($Changes.Count -gt 0) {
        # Populate rows dynamically
        foreach ($change in $Changes) {
            $grid.Rows.Add($($change.Noun), $($change.Verb), $($change.Name),$($change.Path))
        }

        # Add an OK button
        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Size = New-Object System.Drawing.Size(80, 30)
        $okButton.Location = New-Object System.Drawing.Point(230, 240)
        $okButton.Add_Click({ $form.Close() })

        # Add controls to the form
        $form.Controls.Add($grid)
        $form.Controls.Add($okButton)

        # Show the form as a dialog
        $form.ShowDialog()
    } else {
        Write-Host "No changes detected compared to the previous version."
    }
} else {
    Write-Host "This is the first scan version. No prior CSV found for comparison."
}