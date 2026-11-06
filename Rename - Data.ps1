<#
.SYNOPSIS
    Renames photos based on Sequence Number and Timestamp from a CSV file.

.DESCRIPTION
    Reads a CSV file with columns "Sequence Number" and "Time stamp".
    Finds images in a specified folder whose filenames contain timestamps.
    Filters images between each timestamp and the next row's timestamp.
    Renames them to the Sequence Number, adding A/B/C if multiple images fall in the same range.

.NOTES
    Author: Senior Tech Expert
    Date: 2026-10-19
#>

# --- CONFIGURATION ---
$csvPath   = "C:\Users\Nathan.Sanders\Documents\Level 2.csv"      # Path to CSV file
$imagePath = "C:\Users\Nathan.Sanders\Desktop\Trav phone 10.8"        # Path to folder containing images
$Log = "C:\Users\Nathan.Sanders\Documents\Level 2.txt"
"Airport Terminal B - $((Get-ChildItem -Path $csvPath).BaseName)" | Out-File $Log
# --- INPUT VALIDATION ---
if (-not (Test-Path $csvPath)) {
    Write-Error "CSV file not found at $csvPath"
    exit
}
if (-not (Test-Path $imagePath)) {
    Write-Error "Image folder not found at $imagePath"
    exit
}

try {
    $csvData = Import-Csv $csvPath
} catch {
    Write-Error "Failed to read CSV file: $_"
    exit
}

# Ensure CSV has required columns
if (-not ($csvData | Get-Member -Name "Sequence Number" -MemberType NoteProperty) -or
    -not ($csvData | Get-Member -Name "Time stamp" -MemberType NoteProperty)) {
    Write-Error "CSV must contain 'Sequence Number' and 'Time stamp' columns."
    exit
}

# --- PARSE CSV AND SORT BY TIMESTAMP ---
$TimeStampData = $csvData.'Time Stamp'
$TimeStamps = @()
foreach ($Timestamp in $TimeStampData) {
    $TimeStamps+=$Timestamp.Replace(":","")
}

# --- GET IMAGE FILES ---
$imageFiles = Get-ChildItem -Path "$imagePath\*.*" -Include ("*.jpg", "*.jpeg")

# --- PROCESS EACH CSV ROW ---
$Count = (0..$($csvData.Count-1))
foreach ($C in $Count) {
    $currentRow = ($($csvData.'Sequence Number'[$C]),$($TimeStamps[$C]))
    $nextRow    = if ($C -lt $Count.Count-1) { ($($csvData.'Sequence Number'[$C+1]),$($TimeStamps[$C+1])) } else { $null }
    if ($nextRow) {
        $TimeValues = ("$($currentRow[1].Substring(0, $($currentRow[1]).Length - 2))".."$($nextRow[1].Substring(0, $($nextRow[1]).Length - 2)-1)")
    }
    else {
        $TimeValues = ("$($currentRow[1].Substring(0, $($currentRow[1]).Length - 2))".."2359")
    }

    $ReGex = ".*_("
    foreach ($TimeValue in $TimeValues) {
        $ReGex += "$TimeValue(0*[1-9]\d)|"
    }
    $ReGex = "$($ReGex.Substring(0, $ReGex.Length - 1))).*"
    $imagesInRange = @()
    ForEach($imageFile in $imageFiles) {
        if ($imageFile.Name -match $ReGex) <# Matches yyyyMMdd_HHmmss#> {
            $imagesInRange += $imageFile
            "$($imageFile.Name) is withing the range $ReGex"
        }
        else {
            "$($imageFile.Name) is not within the current range"
        }
    } 

    if ($imagesInRange.Count -gt 0) {
        for ($j = 0; $j -lt $imagesInRange.Count; $j++) {
            $suffix = if ($j -eq 0) { "" } else { ".$j" } # 1, 2, 3...
            $newName = if ($suffix -eq "") { "{0}" -f $($currentRow[0])} else { "{0}{1}" -f $($currentRow[0]), $suffix }

            try {
                Rename-Item -Path $imagesInRange[$j].FullName -NewName ($newName + $imagesInRange[$j].Extension)
                Write-Host "Renamed '$($imagesInRange[$j].Name)' to '$newName$($imagesInRange[$j].Extension)'"
                "Renamed '$($imagesInRange[$j].Name)' to '$newName$($imagesInRange[$j].Extension)'" | Out-File $Log -Append
            } catch {
                Write-Warning "Failed to rename '$($imagesInRange[$j].Name)': $_"
            }
        }
    }
}

Write-Host "Renaming complete."
