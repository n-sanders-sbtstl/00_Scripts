
$Directory = "C:\Users\Nathan.Sanders\Documents\Test\Sheet sorting"

$Files = @()
$Files = (Get-ChildItem -Path $Directory -Filter "S*").BaseName
foreach ($File in $Files) {
    $pdfPath = "$Directory\$File"
    if (Test-Path -Path $pdfPath) {
        "The $file folder already exists"
    }
    else {
        "Making the <$File> folder"
        New-Item -Path $pdfPath -ItemType Directory
        "Moving the [$File.pdf] into the <$File> folder"
        Move-Item -Path "$pdfPath.pdf" -Destination $pdfPath
    }
    if (Test-Path -Path "$pdfPath\Details") {
        "The Details folder already exists for the $File sheet"
    }
    else {
        "Making the Details folder for the $File sheet"
        New-Item -Path "$pdfPath\Details" -ItemType Directory
    }
    $SubFiles = @()
    $SubFiles = (Get-ChildItem -Path $Directory -Filter "Detail*$File*.pdf").BaseName
    
    foreach ($SubFile in $SubFiles) {
        Move-Item -Path "$Directory\$SubFile.pdf" -Destination "$pdfPath\Details"
        $string = $SubFile
        $lastPart = ($string -split ' - ')[ -1 ]
        Rename-Item -Path "$pdfPath\Details\$SubFile.pdf" -NewName "$lastPart.pdf"
    }
}
