# Import the ImportExcel module (if not already installed)
# Install-Module ImportExcel -Scope CurrentUser -Force

# Define the starting directory (change as needed)

$StartPath = "S:\Working Projects"
$EXCLUDES = Get-Content -Path "C:\Users\Nathan.Sanders\Documents\DSExclude.csv"
# Get all directories recursively
$Folders = Get-ChildItem -Path $StartPath -Exclude $EXCLUDES -Directory -ErrorAction Stop
# Create an array to hold the results
"Name,Parent" | Out-File -Path "C:\Users\Nathan.Sanders\Documents\DS Folder\FolderStructure.csv"
foreach ($Folder in $Folders) {
    $Name = $Folder.BaseName
    $ParentName = $Folder.PSParentPath -replace ".*\\",""
    "$Name,$ParentName" | Out-File -Path "C:\Users\Nathan.Sanders\Documents\DS Folder\FolderStructure.csv" -Append
    $SubFolders = Get-ChildItem -Path $Folder.FullName -Directory -ErrorAction Stop
    foreach ($SubFolder in $SubFolders) {
        $SubName = $SubFolder.BaseName
        $SubParentName = $SubFolder.PSParentPath -replace ".*\\",""
        "$SubName,$SubParentName" | Out-File -Path "C:\Users\Nathan.Sanders\Documents\DS Folder\FolderStructure.csv" -Append
    }
}