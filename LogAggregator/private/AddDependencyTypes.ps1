function AddDependencyTypes {
  [CmdletBinding()]
  param(
    [string[]]
    $dependencies
  )
  SetupExternalDependencies -dependencies $dependencies

  Write-Verbose "Adding types from dependecies..."

  Get-ChildItem $PackageDependeciesPublished
  Get-ChildItem -Path $PackageDependeciesPublished -Filter "*.dll" | ForEach-Object {
    $dll = $PSItem.FullName
    Add-Type -Path $dll
    Write-Verbose "Dependency '$dll' types added."
  }
}
