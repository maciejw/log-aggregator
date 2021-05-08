function GetAnsiColor {
  param (
    [ValidateSet('black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white')]
    [Parameter(ParameterSetName = "216")]
    [Alias("c")]
    $Color,
    [Parameter(ParameterSetName = "216")]
    [ValidateRange(0, 5)]
    [Alias("i")]
    $Intensity = 3,
    [Alias("hi")]
    [switch]
    $HighIntensity
  )
  if ($PSBoundParameters.Keys.Contains("Intensity")) {
    $r, $g, $b = switch ($Color) {
      'black' { @((5 - $intensity), (5 - $intensity), (5 - $intensity)) }
      'red' { @($intensity, 0, 0) }
      'green' { @(0, $intensity, 0) }
      'yellow' { @($intensity, $intensity, 0) }
      'blue' { @(0, 0, $intensity) }
      'magenta' { @($intensity, 0, $intensity) }
      'cyan' { @(0, $intensity, $intensity) }
      'white' { @(($intensity), ($intensity), ($intensity)) }
    }
    return 16 + 36 * $r + 6 * $g + $b
  }

  $HighIntensityNumber = 0
  if ($HighIntensity) {
    $HighIntensityNumber = 8
  }
  $ColorNumber = switch ($Color) {
    'black' { 0 + $HighIntensityNumber }
    'red' { 1 + $HighIntensityNumber }
    'green' { 2 + $HighIntensityNumber }
    'yellow' { 3 + $HighIntensityNumber }
    'blue' { 4 + $HighIntensityNumber }
    'magenta' { 5 + $HighIntensityNumber }
    'cyan' { 6 + $HighIntensityNumber }
    'white' { 7 + $HighIntensityNumber }
  }
  return $ColorNumber

}
