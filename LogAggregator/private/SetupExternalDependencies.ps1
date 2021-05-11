$PackageDependecies = "$PSScriptRoot\PackageDependecies"
$PackageDependeciesPublished = "$PSScriptRoot\PackageDependeciesPublished"

function dotnet {
  dotnet.exe @args | Out-String | Write-Verbose
  if ($LASTEXITCODE -ne 0) {
    throw "dotnet exited with $LASTEXITCODE"
  }

}

function SetupExternalDependencies {
  [CmdletBinding()]
  param(
    [string[]]
    $dependencies
  )
  Write-Verbose "Setting up dependecies..."

  if ((Test-Path $PackageDependecies) -eq $false) {
    Write-Verbose "Creating dependency project..."
    dotnet new classlib -o $PackageDependecies
  }
  $dependencies | ForEach-Object {
    Write-Verbose "Adding dependency '$PSItem' to the project..."

    $isDependencyPresent = dotnet list $PackageDependecies package | Select-String -Pattern $PSItem -Quiet
    if ($isDependencyPresent) {
      Write-Verbose "Dependency already added"
    } else {
      dotnet add $PackageDependecies package $PSItem --prerelease
      Write-Verbose "Dependency added"
    }
  }
  Write-Verbose "Publishing dependencies project..."
  dotnet publish $PackageDependecies -o $PackageDependeciesPublished
}
