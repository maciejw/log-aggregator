$Private = @(Get-ChildItem -Path $PSScriptRoot\Private -Recurse -Filter "*.ps1" | Sort-Object Name)
$Public = @(Get-ChildItem -Path $PSScriptRoot\Public -Recurse -Filter "*.ps1" | Sort-Object Name)

foreach ($item in ($Private + $Public)) {
  try {
    $function = $item.FullName
    . $function
    Write-Verbose -Message ("Dot sourcing '{0}' script" -f $function)
  } catch {
    Write-Error -Message ("Failed to dot source '{0}' script: {1}" -f $function, $_)
  }
}

AddDependencyTypes -dependencies MessageTemplates

Export-ModuleMember -Function $Public.BaseName
