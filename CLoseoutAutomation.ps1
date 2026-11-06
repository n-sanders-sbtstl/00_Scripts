# Enable .NET Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Select an Option"
$form.Size = New-Object System.Drawing.Size(300,150)
$form.StartPosition = "CenterScreen"

# Create a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Please choose an option:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

# Create a ComboBox (drop-down list)
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10,50)
$comboBox.Size = New-Object System.Drawing.Size(260,20)
$comboBox.DropDownStyle = 'DropDownList'  # Prevents typing, selection only

# Add options to the drop-down
$comboBox.Items.AddRange(@(
    "30% - Submittal",
    "60% - Submittal",
    "90% - Submittal",
    "100% - Submittal",
    "IFC - Submittal",
    "IFB - Submittal",
    "Cancel"
))
$comboBox.SelectedIndex = 0  # Default selection
$form.Controls.Add($comboBox)

# Create an OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(100,80)
$okButton.Add_Click({
    if ($comboBox.SelectedItem) {
        $form.Tag = $comboBox.SelectedItem
        $form.Close()
    }
})
$form.Controls.Add($okButton)

# Show the form as a dialog
$form.ShowDialog() | Out-Null

# Capture the selected value
$selectedOption = $form.Tag

[System.Windows.MessageBox]::Show("You selected: $selectedOption", "Selection Result")
<#
# Output the result
if ($null -ne $selectedOption) {
    Write-Host "You selected: $selectedOption"
    if ($selectedOption -ne "Cancel") {
        Write-Host "SOMETHING NEED DOING!?!"
         Get the directory where this script is located
        #$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
        $ScriptDir = "S:\Working Projects\2023 Projects\J23003 - Northland Secondary Pump Station_B&V\06 QC Checklist\Automation"

        # Go two levels up from the script's location
        $Parent2Dir = ((Split-Path -Parent (Split-Path -Parent $ScriptDir)) -split "(\\)")
        $ProjectFullName = $($Parent2Dir[-1])
        $ProjectNumber = $(($ProjectFullName -split "( - )")[0])
        $Year = "20$($ProjectNumber[1])$($ProjectNumber[2])"

        # Define source and destination folders relative to the 2nd generation parent
        $SourceFolder = "S:\Working Projects\$Year Projects\$ProjectNumber*\02 Outgoing\00 In-House\30% Submittal"       # Change name as needed
        $DestinationFolder = Join-Path $Parent2Dir "DestinationFolder" # Change name as needed

        try {
            # Validate that the source folder exists
            if (-not (Test-Path -Path $SourceFolder -PathType Container)) {
                throw "Source folder not found: $SourceFolder"
            }
            if (-not (Test-Path -Path $DestinationFolder -PathType Container)) {
                throw "Source folder not found: $SourceFolder"
            }

            # Copy contents from source to destination
            Copy-Item -Path (Join-Path $SourceFolder "*") -Destination $DestinationFolder -Recurse -Force

            Write-Host "Files copied successfully from '$SourceFolder' to '$DestinationFolder'."
        }
        catch {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Automation Terminated."
    }
} else {
    Write-Host "Automation Terminated."
}#>

