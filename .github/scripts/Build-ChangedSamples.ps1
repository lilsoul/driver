[CmdletBinding()]
param (
    [array]$ChangedFiles
)

$Verbose = $false
if ($PSBoundParameters.ContainsKey('Verbose')) {
    $Verbose = $PsBoundParameters.Get_Item('Verbose')
}

$root = (Get-Location).Path

# Search for samples (directories) to build
$sampleSet = @{}
$buildAll = $false
foreach ($file in $ChangedFiles) {
    if (-not (Test-Path $file)) {
        Write-Verbose "`u{2754} Changed file $file cannot be found"
        continue
    }
    $dir = (Get-Item $file).DirectoryName
    $origdir = $dir
    $filename = Split-Path $file -Leaf

    # Files that can affect how every sample is built should trigger a full build
    if ($filename -eq "Build-AllSamples.ps1" -or $filename -eq "Build-Sample.ps1") {
        $buildAll = true
    }
    if ($dir -like "*\.github\scripts" -or $dir -like "*\.github\scripts\*") {
        $buildAll = true
    }
    if ($dir -like "*\.github\workflows" -or $dir -like "*\.github\workflows\*") {
        $buildAll = true
    }
    if ($buildAll)
    {
        Write-Verbose "`u{2754} Full build triggered by change in file $file"
        break
    }

    while ((-not ($slnItems = (Get-ChildItem $dir '*.sln'))) -and ($dir -ne $root)) {
        $dir = (Get-Item $dir).Parent.FullName
    }
    if ($dir -eq $root) {
        Write-Verbose "`u{2754} Changed file $file at $origdir does not match a sample"
        continue
    }
    $sampleName = $dir.Replace($root, '').Trim('\').Replace('\', '.').ToLower()
    Write-Verbose "`u{1F50E} Found sample [$sampleName] at $dir from changed file $file"
    if (-not ($sampleSet.ContainsKey($sampleName))) {
        $sampleSet[$sampleName] = $dir
    }
}

if ($buildAll) {
    .\Build-AllSamples -Verbose:$Verbose -LogFilesDirectory (Join-Path $root "_logs")
}
else {
    .\Build-SampleSet -SampleSet $sampleSet -Verbose:$Verbose -LogFilesDirectory (Join-Path $root "_logs")
}

