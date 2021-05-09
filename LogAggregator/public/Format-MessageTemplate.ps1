function FormatValue {
  param (
    $value,
    $color
  )
  $value | Format-AnsiColor -fg $color -fgi 3
}

Class AnsiFormatProvider : System.IFormatProvider, System.ICustomFormatter {

  [object] GetFormat([Type] $formatType) {
    if ($formatType -eq [ICustomFormatter]) {
      return $this;
    } else {
      return $null;
    }
  }

  [string] Format([string] $fmt, [object] $arg, [IFormatProvider] $formatProvider) {
    if ($arg.GetType() -eq [System.Boolean]) {
      return FormatValue $arg "green"
    } else {
      return FormatValue $arg "magenta"
    }
  }
}



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
  $formatedValue = switch ($value.GetType()) {
    {
      $PSItem -eq [System.String]
    } {
      FormatValue $value 'cyan'
    }
    Default {
      $value
    }
  }

  return [MessageTemplates.Structure.ScalarValue]::new($formatedValue);
}

function CreateProperty([string] $name, [object]$value) {
  $propertyValue = CreatePropertyValue $value
  return  [MessageTemplates.Structure.TemplateProperty]::new($name, $propertyValue)
}

function GetColorFromLogLevel ($LogLevel) {
  switch ($LogLevel) {
    "Trace" { @{fg = "cyan"; fgi = 1 } }
    "Debug" { @{fg = "magenta" ; fgi = 2 } }
    "Information" { @{ fg = "white"; fgi = 3 } }
    "Warning" { @{ fg = "yellow"; fgi = 5 } }
    "Error" { @{ fg = "red"; fgi = 5 } }
    "Critical" { @{ fg = "white"; fgi = 4; bg = "red"; bgi = 5 } }
    Default { @{ fg = "white"; fgi = 3 } }
  }
}

function Format-MessageTemplate {
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [pscustomobject]
    $item,
    [string[]]
    $includeProperties
  )
  begin {  }
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
      $message = $messageTemplate.Render($templateProperties, [AnsiFormatProvider]::new())
    }

    $color = GetColorFromLogLevel $level

    $logEntry = @(
      ("$timestamp" | Format-AnsiColor -fg "white" -fgi $color.fgi),
      ("[$($level.PadRight(11))]" | Format-AnsiColor @color),
      ("$message" | Format-AnsiColor -fg "white" -fgi $color.fgi)
    )

    $logEntry -join " "
    if ($includeProperties) {
      $includedData = $item | Select-Object -Property $includeProperties
      $existingProperties = $includedData.PSObject.Properties | Where-Object { $null -NE $PSItem.Value } | ForEach-Object Name
      if ($existingProperties) {
        $includedData | Select-Object $existingProperties | Out-String | Format-AnsiColor
      }
    }
  }
}
