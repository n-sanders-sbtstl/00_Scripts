$RootDirectory = "S:\Front Office1\MEAT System Templates & Documents"

$Pattern = "RYG"

# Validate that the directory exists
if (-not (Test-Path -Path $RootDirectory -PathType Container)) {
    Write-Error "The specified directory '$RootDirectory' does not exist or is not a folder."
    exit 1
}

try {
    # Recursively get all files, skipping inaccessible folders
    Get-ChildItem -Path $RootDirectory -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            try {
                # Search for the string $Pattern
                $Mymatches = Select-String -Path $_.FullName -Pattern $Pattern -ErrorAction SilentlyContinue
                if ($Mymatches) {
                    Write-Output "Match found in file: $($_.FullName)"
                }
            }
            catch {
                Write-Warning "Could not read file: $($_.FullName) - $_"
            }
        }
}
catch {
    Write-Error "An unexpected error occurred: $_"
}