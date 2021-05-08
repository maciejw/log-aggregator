function Format-AnsiColor {
  [CmdletBinding()]
  [OutputType([String])]
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true
    )]
    [AllowEmptyString()]
    [String]
    $Message,

    [Parameter()]
    [ValidateSet('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')]
    [Alias('fg')]
    [String]
    $ForegroundColor = 'white',

    [Parameter()]
    [ValidateRange(0, 5)]
    [Alias('fgi')]
    $ForegroundColorIntensity = 3,

    [Parameter()]
    [ValidateSet('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')]
    [Alias('bg')]
    [String]
    $BackgroundColor,

    [Parameter()]
    [ValidateRange(0, 5)]
    [Alias('bgi')]
    $BackgroundColorIntensity
  )

  Begin {
    $e = [char]27
  }

  Process {
    $formats = @()

    if ($ForegroundColor) {
      $f = GetAnsiColor -Color $ForegroundColor -Intensity $ForegroundColorIntensity;
      $formats += "38;5;$f"
    }
    if ($BackgroundColor) {
      $b = GetAnsiColor -Color $BackgroundColor -Intensity $BackgroundColorIntensity;
      $formats += "48;5;$b"
    }
    if ($formats) {
      $formatter = "$e[$($formats -join ';')m"
    }
    $default = "$e[0m"

    "$formatter$PSItem$default"
  }
}
