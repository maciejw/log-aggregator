function ShowLogs {
  param (
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $logFiles,
    [scriptblock]
    $filter
  )


  if ($null -eq $filter) {
    $filter = { $true }
  }

  $logFiles | ForEach-Object {
    $logFile = $_
    Start-Job {
      $filterScript = [ScriptBlock]::Create($using:filter)
      Get-Content $using:logFile | ConvertFrom-Json | Where-Object {
        return $filterScript.InvokeWithContext($null, @([psvariable]::new("log", $_)))
      }
    }
  } | Wait-Job | ForEach-Object {
    $_ | Receive-Job
  } | Sort-Object "@t"
}
