Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
"
  ____  _    _ _      _  __      _____  ______ _   _          __  __ ______ 
 |  _ \| |  | | |    | |/ /     |  __ \|  ____| \ | |   /\   |  \/  |  ____|
 | |_) | |  | | |    |   /      | |__) | |__  |  \| |  /  \  | \  / | |__   
 |  _ <| |  | | |    |  <       |  _  /|  __| |     | / /\ \ | |\/| |  __|  
 | |_) | |__| | |____|   \      | | \ \| |____| |\  |/ ____ \| |  | | |____ 
 |____/ \____/|______|_|\_\     |_|  \_\______|_| \_/_/    \_\_|  |_|______|
                                                                            
  _______ ____   ____  _      
 |__   __/ __ \ / __ \| |     
    | | | |  | | |  | | |     
    | | | |  | | |  | | |     
    | | | |__| | |__| | |____ 
    |_|  \____/ \____/|______|
                              
                              "


# Load required assembly for Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Function to show a message box with Continue/Cancel
function Show-IntroDialog {
    $message = "
This tool is designed to be used as a bulk renaming toolbased on a specified file extension. 

All the files in a chosen directory will be renamed with a standard name followed by a count indicator

(Example: Preliminary_Detail - 1.pdf)

DO NOT ADD THE SEPARATOR ' - ' BEFORE THE NUMBER  
The ' - ' is added by default

This script will ask you for three pieces of information:
    1. The directory location for the files you wish to rename
    2. The file extension of the desired files
    3. The standard name you wish to use"

Click 'Continue' to proceed or 'Cancel' to exit.
    $caption = "Bulk Renaming Tool"
    $buttons = [System.Windows.Forms.MessageBoxButtons]::OKCancel
    $icon = [System.Windows.Forms.MessageBoxIcon]::Information

    return [System.Windows.Forms.MessageBox]::Show($message, $caption, $buttons, $icon)
}

# Function to prompt for text input
function Get-UserInput($prompt, $title) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(410,200)
    $form.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $prompt
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20,20)
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(20,50)
    $textbox.Width = 260
    $form.Controls.Add($textbox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Location = New-Object System.Drawing.Point(110,80)
    $okButton.Add_Click({ $form.Tag = $textbox.Text; $form.Close() })
    $form.Controls.Add($okButton)

    $form.AcceptButton = $okButton

    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# --- Main Script Execution ---

# Step 1: Show intro dialog
$response = Show-IntroDialog

if ($response -eq [System.Windows.Forms.DialogResult]::Cancel) {
    Write-Host "User cancelled. Exiting script."
    exit
}

# Step 2: Ask for three inputs
$FolderLocation = Get-UserInput "What is the directory of the files you wish to rename?:
( Example:     C:\Your\Directory\Path     )"  "Input 1 of 3"
if (-not $FolderLocation) { Write-Host "Cancelled."; exit }

$FileExtension = Get-UserInput "What is the file extension of the files you wish to rename?:
( Example:     .pdf     )"  "Input 2 of 3"
if (-not $FileExtension) { Write-Host "Cancelled."; exit }

$RootName = Get-UserInput "What is the file name you would like to use for this bulk renaming?:
( Example:     Preliminary_Detail     )" "Input 3 of 3"
if (-not $RootName) { Write-Host "Cancelled."; exit }


$Files = @()
$Files = (Get-ChildItem -path $FolderLocation -Filter "*$FileExtension").FullName
$Count = 1
foreach ($File in $Files) {
    $FileName = "$RootName - $Count"
    #Rename-Item -Path $File -NewName "$FileName$FileExtension"
    "$File - is now - $FileName$FileExtension"
    $Count += 1
}
"
  _______        _____ _  __       _____ ____  __  __ _____  _      ______ _______ ______ 
 |__   __|/\    / ____| |/ /      / ____/ __ \|  \/  |  __ \| |    |  ____|__   __|  ____|
    | |  /  \  | (___ |   /      | |   | |  | | \  / | |__) | |    | |__     | |  | |__   
    | | / /\ \  \___ \|  <       | |   | |  | | |\/| |  ___/| |    |  __|    | |  |  __|  
    | |/ ____ \ ____) |   \      | |___| |__| | |  | | |    | |____| |____   | |  | |____ 
    |_/_/    \_\_____/|_|\_\      \_____\____/|_|  |_|_|    |______|______|  |_|  |______|
                                                                                          
                                                                                          "

                                                                                          


