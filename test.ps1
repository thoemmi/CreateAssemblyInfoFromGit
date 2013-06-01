$script:counter = 1
$testpath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())

function AddFileAndCommit {
    Set-Content -Path "$script:counter.txt" -Value $script:counter
    git add "$script:counter.txt" | Out-Null
    git commit -m "$script:counter" | Out-Null
    $script:counter = $script:counter + 1
}

function AddTag {
    param ([Parameter(Mandatory=$true)][string] $name)
    git tag -a $name -m "tag for $name"
}

function Assert {
    param ([Parameter(Mandatory=$true)] $expectedVersion, [Parameter(Mandatory=$true)] $expectedInfoVersion)
    $actual = [CreateAssemblyInfoFromGit.GitHelper]::GetVersion($testpath);
    if ($expectedInfoVersion -ne $($actual.AssemblyInformationalVersion)) { throw "Expected semantic version $expectedInfoVersion, but was $($actual.AssemblyInformationalVersion)" }
    if ($expectedVersion -ne $($actual.AssemblyVersion)) { throw "Expected assembly version $expectedVersion, but was $($actual.AssemblyVersion)" }
}

function Test {
    param (
        [Parameter(Mandatory=$true)][string] $path
    )
    Write-Host Testing...
    git init .
    git config user.email "you@example.com"
    git config user.name "Your Name"

    AddFileAndCommit
    Assert "0.0.0.0" "0.0.0-beta0000"

    AddFileAndCommit
    Assert "0.0.0.1" "0.0.0-beta0001"

    AddFileAndCommit
    AddTag "vNext-1.0"
    Assert "1.0.0.0" "1.0.0-beta0000"

    AddFileAndCommit
    Assert "1.0.0.1" "1.0.0-beta0001"

    AddFileAndCommit
    Assert "1.0.0.2" "1.0.0-beta0002"

    AddFileAndCommit
    AddTag "v-1.0"
    Assert "1.0.0.3" "1.0.0"

    AddFileAndCommit
    Assert "1.0.1.0" "1.0.1"

    AddFileAndCommit
    Assert "1.0.2.0" "1.0.2"

    AddFileAndCommit
    AddTag "vNext-1.1"
    Assert "1.1.0.0" "1.1.0-beta0000"

    AddFileAndCommit
    Assert "1.1.0.1" "1.1.0-beta0001"

    AddFileAndCommit
    AddTag "v-1.1"
    AddTag "vNext-1.2"
    Assert "1.1.0.2" "1.1.0"

    AddFileAndCommit
    Assert "1.2.0.1" "1.2.0-beta0001"

    Write-Host "All tests passed" -ForegroundColor Green
}


Add-Type -Path (join-path (Split-Path $MyInvocation.MyCommand.Path) "src\CreateAssemblyInfoFromGit\bin\Release\CreateAssemblyInfoFromGit.dll")

New-Item -Path $testpath -ItemType directory  | Out-Null
Push-Location  $testpath
try{
    Test -path $testpath
}
finally {
    Pop-Location
    #Remove-Item -Path $testpath -Recurse -Force | Out-Null
}