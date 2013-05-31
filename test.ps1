$script:counter = 1

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
    param ([Parameter(Mandatory=$true)] $expected, [Parameter(Mandatory=$true)] $actual)
    if ($expected -ne $actual) { throw "Expected $expected, but was $actual" }
}

function Test {
    param (
        [Parameter(Mandatory=$true)][string] $path
    )
    Write-Host Testing...
    git init .
    git config user.email "you@example.com"
    git config user.name "Your Name"

    # no tags, just one commit
    AddFileAndCommit
    Assert -expected "0.0.0-beta1" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # no tags, two commits
    AddFileAndCommit
    Assert -expected "0.0.0-beta2" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # announce vNext 1.0
    AddTag -name "vNext-1.0"
    Assert -expected "1.0-beta0" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # tag v1.0
    AddFileAndCommit
    AddTag -name "v1.0"
    Assert -expected "1.0.0" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # one commit after tag v1.0
    AddFileAndCommit
    Assert -expected "1.0.1" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # tag v1.1
    AddTag -name "v1.1"
    Assert -expected "1.1.0" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # one commit after tag v1.1
    AddFileAndCommit
    Assert -expected "1.1.1" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # announcing next version via vNext tag
    AddTag -name "vNext-1.2"
    Assert -expected "1.2-beta0" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    # two cimmit after vNext tag
    AddFileAndCommit
    AddFileAndCommit
    Assert -expected "1.2-beta2" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    AddTag -name "v1.2"
    Assert -expected "1.2.0" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    AddFileAndCommit
    Assert -expected "1.2.1" -actual ([CreateAssemblyInfoFromGit.GitHelper]::GetVersion($path))

    Write-Host "All tests passed" -ForegroundColor Green
}


Add-Type -Path (join-path (Split-Path $MyInvocation.MyCommand.Path) "src\CreateAssemblyInfoFromGit\bin\Release\CreateAssemblyInfoFromGit.dll")

$testpath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
New-Item -Path $testpath -ItemType directory  | Out-Null
Push-Location  $testpath
try{
    Test -path $testpath
}
finally {
    Pop-Location
    #Remove-Item -Path $testpath -Recurse -Force | Out-Null
}