
<#
.SYNOPSIS
    Recursively lists all directories in a specified folder and appends them to a CSV file
    with columns: Directory, NumberOfSubfolders.

.PARAMETER RootPath
    The root folder to scan.

.PARAMETER OutputCsv
    The CSV file path to append results to.

.EXAMPLE
    .\Get-Directories.ps1 -RootPath "C:\TestFolder" -OutputCsv "C:\output.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$RootPath
)

try {
    # Validate that the root path exists
    if (-not (Test-Path -Path $RootPath -PathType Container)) {
        throw "The specified path '$RootPath' does not exist or is not a directory."
    }
    $EXCLUDES = Get-Content -Path "C:\Users\Nathan.Sanders\Documents\DSExclude.csv"
    # Get all directories recursively
    $directories = Get-ChildItem -Path $RootPath -Exclude $EXCLUDES -Directory -ErrorAction Stop
    foreach ($dir in $directories) {
        $OutputCsv = "C:\Users\Nathan.Sanders\Documents\DS Folder\$($dir.BaseName).csv"
        # Prepare results
        $results = [PSCustomObject]@{
            Path            = $dir.FullName
        }
        $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
        $subfolders = (Get-ChildItem -Path $dir.FullName -Directory -Recurse -ErrorAction SilentlyContinue)
        foreach ($subfolder in $subfolders) {
            # Count immediate subfolders
            $results = [PSCustomObject]@{
                Path            = $subfolder.FullName
            }
            $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8 -Append
        }
    }
    Write-Host "Directory list successfully written to $OutputCsv" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
