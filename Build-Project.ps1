param(
    $Directory,
    [string]$ProjectName,
    $LogFilesDirectory,
    [string]$Configuration = "Debug",
    [string]$Platform = "x64"
)

# TODO Validate $Directory and $LogFilesDirectory
New-Item -ItemType Directory -Force -Path $LogFilesDirectory | Out-Null

if ([string]::IsNullOrWhitespace($ProjectName))
{
    $ProjectName = (Resolve-Path $Directory).Path.Replace((Get-Location), '').Replace('\', '.').Trim('.').ToLower()
}

$solutionFile = Get-ChildItem -Path $Directory -Filter *.sln | Select-Object -ExpandProperty FullName -First 1

$configurationIsSupported = $false
$inSolutionConfigurationPlatformsSection = $false
foreach ($line in Get-Content -Path $solutionFile)
{
    if (-not $inSolutionConfigurationPlatformsSection -and $line -match "\s*GlobalSection\(SolutionConfigurationPlatforms\).*")
    {
        $inSolutionConfigurationPlatformsSection = $true;
        continue;
    }
    elseif ($line -match "\s*EndGlobalSection.*")
    {
        $inSolutionConfigurationPlatformsSection = $false;
        continue;
    }

    if ($inSolutionConfigurationPlatformsSection)
    {
        [regex]$regex = ".*=\s*(?<ConfigString>(?<Configuration>.*)\|(?<Platform>.*))\s*"
        $match = $regex.Match($line)
        if ([string]::IsNullOrWhiteSpace($match.Groups["ConfigString"].Value) -or [string]::IsNullOrWhiteSpace($match.Groups["Platform"].Value))
        {
            Write-Warning "Could not parse configuration entry $line from file $solutionFile."
            continue;
        }
        if ($match.Groups["Configuration"].Value.Trim() -eq $Configuration -and $match.Groups["Platform"].Value.Trim() -eq $Platform)
        {
            $configurationIsSupported = $true;
        }
    }
}

if (-not $configurationIsSupported)
{
    # jjj42: Write-Output "[$ProjectName] `u{23E9} Skipped. Configuration $Configuration|$Platform not supported."
    exit 2
}

$errorLogFilePath = "$LogFilesDirectory\$ProjectName.$Configuration.$Platform.err"
$warnLogFilePath = "$LogFilesDirectory\$ProjectName.$Configuration.$Platform.wrn"
$OutLogFilePath = "$LogFilesDirectory\$ProjectName.$Configuration.$Platform.out"
# jjj42: Write-Output "Building Project: $ProjectName; Configuration: $Configuration; Platform: $Platform {"
#sleep 1
msbuild $solutionFile -clp:Verbosity=m -t:clean,build -property:Configuration=$Configuration -property:Platform=$Platform -p:TargetVersion=Windows10 -p:InfVerif_AdditionalOptions="/msft /sw1205 /sw1324 /sw1420 /sw1421" -p:SignToolWS=/fdws -p:DriverCFlagAddOn=/wd4996 -flp1:errorsonly`;logfile=$errorLogFilePath -flp2:WarningsOnly`;logfile=$warnLogFilePath -noLogo >$OutLogFilePath
#msbuild $solutionFile -clp:Verbosity=m -t:clean,build -property:Configuration=$Configuration -property:Platform=$Platform -p:TargetVersion=Windows10 -p:InfVerif_AdditionalOptions="" -p:SignToolWS=/fdws -p:DriverCFlagAddOn=/wd4996 -flp1:errorsonly`;logfile=$errorLogFilePath -flp2:WarningsOnly`;logfile=$warnLogFilePath -noLogo >$OutLogFilePath
if ($LASTEXITCODE -ne 0)
{
    #jjj Write-Warning "`u{274C} Build failed. Log available at $errorLogFilePath"
    exit 1
}
# jjj42: Write-Output "Building Project: $ProjectName; Configuration: $Configuration; Platform: $Platform }"