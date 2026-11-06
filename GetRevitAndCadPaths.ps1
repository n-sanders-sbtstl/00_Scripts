Add-Type -AssemblyName System.Windows.Forms

# Prompt for Revit file
$revitDialog = New-Object System.Windows.Forms.OpenFileDialog
$revitDialog.Filter = "Revit Files (*.rvt)|*.rvt"
if ($revitDialog.ShowDialog() -ne "OK") { exit }

# Prompt for CAD file
$cadDialog = New-Object System.Windows.Forms.OpenFileDialog
$cadDialog.Filter = "CAD Files (*.dwg;*.dxf)|*.dwg;*.dxf"
if ($cadDialog.ShowDialog() -ne "OK") { exit }

# Output in format: revitPath|cadPath
Write-Output "$($revitDialog.FileName)|$($cadDialog.FileName)"
