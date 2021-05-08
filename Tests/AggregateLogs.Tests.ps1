BeforeAll {
  Remove-Module $PSScriptRoot\..\LogAggregator -ErrorAction SilentlyContinue
  Import-Module $PSScriptRoot\..\LogAggregator -Force
}

Describe "Log Aggregator" {
  Context "WatchLog" {
    It "Should watch for new data" {
      Mock ForEach-Object {
        return $Parallel.InvokeWithContext(@{"Get-Content" = {
              $args[0] | Should -Match "file[1-2]"
              $args[1] | Should -Be "-Wait"
              $args[2] | Should -Be "-Tail"
              $args[3] | Should -Be "0"
              return 1, 2
            }
          }, $null, $null)
      } -Verifiable -ParameterFilter {
        return $ThrottleLimit -eq 2 -and $Parallel -ne $null
      }

      $result = WatchLogs "file1", "file2"

      $result | Should -BeExactly 1, 2, 1, 2

      Should -InvokeVerifiable
    }
  }
  Context "OrderLogs" {
    BeforeAll {
      Push-Location $PSScriptRoot
    }
    AfterAll {
      Pop-Location
    }
    It "Should order files" {
      $files = @(
        '.\OrderLogsData\log1.json',
        '.\OrderLogsData\log2.json'
      )

      $results = ShowLogs $files

      $results | Should -HaveCount 12
      $results."@mt" | ForEach-Object {
        $_ | Should -Match "Message [0-9]"
      }
      $results."@t" | Sort-Object | Should -BeExactly $results."@t"
    }
    It "Should order and filter files" {
      $files = @(
        '.\OrderLogsData\log1.json',
        '.\OrderLogsData\log2.json'
      )

      $results = ShowLogs $files -filter { $log."@mt" -match "Message 2" }
      $results | Should -HaveCount 2
      $results."@mt" | ForEach-Object {
        $_ | Should -Match "Message 2"
      }
    }
  }

  Context "Colors" {
    It "Should calculate Ansi colors for intensity <intensity> and color <color>" -ForEach @(
      @{Intensity = 0; ColorValue = 16; Color = "red" },
      @{Intensity = 1; ColorValue = 52; Color = "red" },
      @{Intensity = 2; ColorValue = 88; Color = "red" },
      @{Intensity = 3; ColorValue = 124; Color = "red" },
      @{Intensity = 4; ColorValue = 160; Color = "red" },
      @{Intensity = 5; ColorValue = 196; Color = "red" }
    ) {
      InModuleScope LogAggregator {
        param($Intensity, $Color)
        GetAnsiColor -Color $Color -Intensity $Intensity
      } -Parameters @{Intensity = $Intensity; Color = $Color } | Should -Be $ColorValue

    }
    It "Should calculate Ansi colors for intensity <HighIntensity> and color <Color>" -ForEach @(
      @{HighIntensity = $false; ColorValue = 0; Color = "black" },
      @{HighIntensity = $false; ColorValue = 1; Color = "red" },
      @{HighIntensity = $false; ColorValue = 2; Color = "green" },
      @{HighIntensity = $false; ColorValue = 3; Color = "yellow" },
      @{HighIntensity = $false; ColorValue = 4; Color = "blue" },
      @{HighIntensity = $false; ColorValue = 5; Color = "magenta" }
      @{HighIntensity = $false; ColorValue = 6; Color = "cyan" }
      @{HighIntensity = $false; ColorValue = 7; Color = "white" },
      @{HighIntensity = $true; ColorValue = 0 + 8; Color = "black" },
      @{HighIntensity = $true; ColorValue = 1 + 8; Color = "red" },
      @{HighIntensity = $true; ColorValue = 2 + 8; Color = "green" },
      @{HighIntensity = $true; ColorValue = 3 + 8; Color = "yellow" },
      @{HighIntensity = $true; ColorValue = 4 + 8; Color = "blue" },
      @{HighIntensity = $true; ColorValue = 5 + 8; Color = "magenta" }
      @{HighIntensity = $true; ColorValue = 6 + 8; Color = "cyan" }
      @{HighIntensity = $true; ColorValue = 7 + 8; Color = "white" }
    ) {
      InModuleScope LogAggregator {
        param($params)
        GetAnsiColor @params
      } -Parameters @{params = @{Color = $Color; HighIntensity = $HighIntensity } } | Should -Be $ColorValue

    }
  }
  It "should color output" {
    InModuleScope LogAggregator {
      'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' | ForEach-Object {
        $color = $PSItem
        0..5 | ForEach-Object { $color | Format-AnsiColor -fg $color -fgi $PSItem } | Write-Verbose
      }
    }
  }
  Context "Formatting" {
    It "should format log" {
      $files = @(
        '.\OrderLogsData\log1.json'
      )
      ShowLogs $files | Format-MessageTemplate | Write-Verbose
    }
  }

  Context "ExternalDependencies" {
    It "it should be possible to use message templates" {
      InModuleScope LogAggregator {
        AddDependencyTypes -dependencies "MessageTemplates"
        [MessageTemplates.MessageTemplate] | Should -Not -Be $null
      }

    }
  }
}
