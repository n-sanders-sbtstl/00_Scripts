$staplerPath = "C:\Program Files\Bluebeam Software\Bluebeam Revu\21\Revu\Stapler.exe"
$folderPath = Read-Host "Enter the Directory location for the PDFs you wish to Staple"
$pdfFiles = Get-ChildItem -Path $folderPath -Recurse -Filter *.pdf | Sort-Object FullName


$PDFName = Read-Host "Enter the Name you would like to assign to the finished/stapled file"
if ($PDFName -match "/.") {
    if ($PDFName -match ".pdf") {
        $combinedPDFName = $PDFName
    }
    else {
        Write-Host "THE FILE EXTENTION MUST BE .pdf!!!!!!!!!" -ForegroundColor Red
        $PDFName = Read-Host "Enter the Name you would like to assign to the finished/stapled file"
        $combinedPDFName = $PDFName
    }
}
else {
    $combinedPDFName = "$PDFName.pdf"
}

$files = @()
foreach ($pdf in $pdfFiles) {
    $files += $($pdf.FullName)
}

$combinedPDFPath = Read-Host "Enter the Directory where you would like to put the finished/stapled file"
$bsxName = $combinedPDFName -replace '\..*$', ''
$BsxFile = "$env:TEMP\$bsxName.bsx"
$bsxIntro = '<?xml version="1.0" encoding="utf-8"?>'
"$bsxIntro" | Out-File -FilePath $BsxFile

$bsxSettings = "<Jobs>
  <Job>
    <OutputFileName>$combinedPDFName</OutputFileName>
    <StampsOnAllPages />
    <OutputDir>$combinedPDFPath</OutputDir>
    <JobOptions>
      <Name>Standard Document.joboptions</Name>
      <Width>-1</Width>
      <Height>-1</Height>
      <Orient>Orientation0</Orient>
      <ImageCompression>Flate</ImageCompression>
      <ImageResolution>300</ImageResolution>
      <JpegQuality>75</JpegQuality>
      <ImageAliasingText>2</ImageAliasingText>
      <ImageAliasingGraphics>2</ImageAliasingGraphics>
      <LineMergeOn>False</LineMergeOn>
      <BlendMode>Darken</BlendMode>
      <BlendAlpha>1</BlendAlpha>
      <PDFPostProcess>False</PDFPostProcess>
      <PostProcessProcessMasks>False</PostProcessProcessMasks>
      <PostProcessFixStripedImageTransparency>False</PostProcessFixStripedImageTransparency>
      <PostProcessCombineAdjacentImages>False</PostProcessCombineAdjacentImages>
      <PostProcessOptimizeSolidImages>False</PostProcessOptimizeSolidImages>
      <PostProcessRemoveTextClipping>False</PostProcessRemoveTextClipping>
      <PostProcessSimplifyClippingPaths>False</PostProcessSimplifyClippingPaths>
      <PostProcessPDFVersion>Version_1_4</PostProcessPDFVersion>
    </JobOptions>
    <ColorDepth>4</ColorDepth>
    <OpenOutputFileAfter>True</OpenOutputFileAfter>
    <DeleteTempPS>False</DeleteTempPS>
    <Name />
    <Overwrite>0</Overwrite>
    <Delete>False</Delete>
    <InterpreterType />
    <LastError />
    <Unfiltered>False</Unfiltered>"
"$bsxSettings" | Out-File -FilePath $BsxFile -Append


foreach ($file in $files) {
    $bsxInput = "    <SubJob>
      <OriginalFileName>$file</OriginalFileName>
      <InputFileName>$file</InputFileName>
      <InputFileType>.pdf</InputFileType>
      <ExeName>Revu</ExeName>
      <ApplicationTitle />
      <PageSize />
      <Orientation />
      <Scale />
      <TransferBookmarks>True</TransferBookmarks>
      <TransferHyperlinks>True</TransferHyperlinks>
      <TransferFileProperties>True</TransferFileProperties>
      <Message />
      <Stamps />
    </SubJob>"
    "$bsxInput" | Out-File -FilePath $BsxFile -Append
}
    

    $bsxConclusion = '  </Job>
</Jobs>'
"$bsxConclusion" | Out-File -FilePath $BsxFile -Append


try {
    # Validate .bsx file exists
    if (-not (Test-Path -Path $BsxFile -PathType Leaf)) {
        throw "The specified .bsx file does not exist: $BsxFile"
    }

    if (-not $staplerPath) {
        throw "Bluebeam Stapler executable not found. Please update the script with the correct path."
    }

    Write-Host "Launching Bluebeam Stapler with job file: $BsxFile" -ForegroundColor Cyan

    # Start Stapler with the .bsx file
    Start-Process -FilePath $staplerPath -ArgumentList "`"$BsxFile`""

    Write-Host "Stapler launched successfully." -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}