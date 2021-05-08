function WatchLogs {
  param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $logFiles
  )
  $logFiles | ForEach-Object -ThrottleLimit $logFiles.Count -Parallel {
    Get-Content $_ -Wait -Tail 0
  }
}
