
function CreatePropertyValue ([object]$value) {
  if ($null -eq $value) {
    return  [MessageTemplates.Structure.ScalarValue]::new($null);
  }

  if ($value.GetType() -eq [System.Collections.ArrayList]) {
    $sequence = $value | ForEach-Object {
      CreatePropertyValue $PSItem
    }
    return [MessageTemplates.Structure.SequenceValue]::new([MessageTemplates.Structure.TemplatePropertyValue[]]$sequence);
  }

  if ($value.GetType().Name -eq "PSCustomObject") {
    $properties = $value.PSObject.Properties | ForEach-Object {
      return CreateProperty $PSItem.Name $PSItem.Value
    }
    return [MessageTemplates.Structure.StructureValue]::new([MessageTemplates.Structure.TemplateProperty[]]$properties)
  }

  return [MessageTemplates.Structure.ScalarValue]::new($value);

}

function CreateProperty([string] $name, [object]$value) {
  $propertyValue = CreatePropertyValue $value
  return  [MessageTemplates.Structure.TemplateProperty]::new($name, $propertyValue)
}

function GetColorForLevel {
  [CmdletBinding()]
  param (
    [Parameter()]
    $Level
  )
  switch ($Level) {
    "Trace" { @{fg = "cyan"; fgi = 1 } }
    "Debug" { @{fg = "magenta" ; fgi = 2 } }
    "Information" { @{ fg = "green"; fgi = 3 } }
    "Warning" { @{ fg = "yellow"; fgi = 4 } }
    "Error" { @{ fg = "red"; fgi = 5 } }
    "Critical" { @{ fg = "white"; fgi = 5 } }
    Default { @{ fg = "white"; fgi = 3 } }
  }
}

function Format-MessageTemplate {
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [pscustomobject]
    $item
  )
  begin {
    # $excludedProperties = @("@mt", "@t", "@l", "PSComputerName", "RunspaceId", "PSShowComputerName")
  }
  process {
    $level = $item."@l"
    $timestamp = $item."@t"

    $messageTemplate = [MessageTemplates.MessageTemplate]::Parse($item."@mt")

    $data = $item | Select-Object -Property $messageTemplate.Tokens.PropertyName
    $properties = $data.PSObject.Properties | ForEach-Object {
      CreateProperty $PSItem.Name $PSItem.Value
    }
    $message = $messageTemplate.Text
    if ($properties) {
      $propertyList = [MessageTemplates.Core.TemplatePropertyList]::new($properties)
      $templateProperties = [MessageTemplates.Core.TemplatePropertyValueDictionary]::new($propertyList);
      $message = $messageTemplate.Render($templateProperties)
    }

    $color = GetColorForLevel -Level $level

    $logEntry = @(
      ("$timestamp" | Format-AnsiColor -fg "white" -fgi $color.fgi),
      ("[$($level.PadRight(11))]" | Format-AnsiColor @color),
      ("$message" | Format-AnsiColor -fg "white" -fgi $color.fgi)
    )

    $logEntry -join " "
    # if (($data.PSObject.Properties | Measure-Object).Count -gt 0) {
    #   $data | ConvertTo-Json -Compress | Format-AnsiColor | Out-Default
    # }
  }
}
