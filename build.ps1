$dir = Split-Path $MyInvocation.MyCommand.Path
$srcdir = Join-Path $dir "src"

#get version from git
. (Join-Path $srcdir "CreateAssemblyInfo.ps1")
Push-Location $dir
$version = Get-VersionFromGit
Pop-Location

# create assembly info
Update-AssemblyInfo $version (Join-Path $srcdir "CreateAssemblyInfoFromGit\CommonAssemblyInfo.cs")


# build
$msbuild = "c:\windows\microsoft.net\framework\v4.0.30319\MSBuild.exe"
$solutionPath = Join-Path $srcdir "CreateAssemblyInfoFromGit.sln"
Invoke-Expression "$msbuild `"$solutionPath`" /p:Configuration=Release /t:Build"

# nupack
$nuget = Join-Path $srcdir ".nuget\nuget.exe"
$nuspec = Join-Path $srcdir "CreateAssemblyInfo.nuspec"
Invoke-Expression "$nuget pack `"$nuspec`" -OutputDirectory $dir -version $version"