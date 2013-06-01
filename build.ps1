$dir = Split-Path $MyInvocation.MyCommand.Path
$srcdir = Join-Path $dir "src"
$assemblyInfoPath = Join-Path $srcdir "CreateAssemblyInfoFromGit\CommonAssemblyInfo.cs"
$assemblyPath = Join-Path $srcdir "CreateAssemblyInfoFromGit\bin\Release\CreateAssemblyInfoFromGit.dll"

function BuildProject {
    $msbuild = "c:\windows\microsoft.net\framework\v4.0.30319\MSBuild.exe"
    $solutionPath = Join-Path $srcdir "CreateAssemblyInfoFromGit.sln"
    Invoke-Expression "$msbuild `"$solutionPath`" /p:Configuration=Release /t:Build"
}

# if CommonAssemblyversion.cs does not exist, create a dummy
if (!(Test-Path $assemblyInfoPath)) {
    Set-Content -Path $assemblyInfoPath -Value ""
}

# first build (we need the assembly to determine our own version)
BuildProject 

# update CommonAssemblyInfo (must be in another AppDomain, because we'll rebuild the assembly later)
$scriptblock = $ExecutionContext.InvokeCommand.NewScriptBlock( 
"Add-Type -Path $assemblyPath
`$ver = [CreateAssemblyInfoFromGit.GitHelper]::GetVersion('$dir')
[CreateAssemblyInfoFromGit.CreateAssemblyInfoFromGit]::CreateOrUpdateAssemblyInfo('$assemblyInfoPath', `$ver, `$Null) | Out-Null
`$(`$ver.AssemblyInformationalVersion)")
$version = powershell -noprofile -nologo -command $scriptblock

Write-Host "Version is $version"

# build again, this time with corrected version
BuildProject 

# test
powershell -noprofile -nologo (Join-Path $dir "test.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Tests failed"
}

# nupack
$nuget = Join-Path $srcdir ".nuget\nuget.exe"
$nuspec = Join-Path $srcdir "CreateAssemblyInfo.nuspec"
Invoke-Expression "$nuget pack `"$nuspec`" -OutputDirectory $dir -version $version"

Write-Host "Package for version $version created." -ForegroundColor Green