# kill any existing jobs on startup
Get-Job Pure__* | Where {$_.State -eq 'Completed' -or $_.State -eq 'Stopped'} | Remove-Job

function asyncGitFetch() {
  # return early if we've fetched recently
  if (Get-Job Pure__* | Where PSBeginTime -ge ((Get-Date) - $pure.FetchInterval)) {
    return
  }

  # clean up any existing jobs
  else {
    Get-Job Pure__* |
    Where { $_.State -eq 'Completed' -or $_.State -eq 'Stopped' } |
    Remove-Job
  }

  # check that we're actually in a git directory
  if ($gitStatus = Get-GitStatus) {

    $null = Start-Job -Name "Pure__GitFetch" -ScriptBlock {
      param($gitDir)

      git -C $gitDir fetch
      # no need to actually do anything here. if the status changed
      # then it should get picked up by the listener

    } -ArgumentList $gitStatus.GitDir
  }
}

function UpdateStatus() {
  $pure._state.isPending = $true
  $null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    $newStatus = &$Global:pure._functions.getStatus
    if (diff $Global:pure._state.status.values $newStatus.values) {
      $Global:pure._state.status = $newStatus
      [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    }
    $pure._state.isPending = $false
  }
}

$Script:UpdateOnChange = {
  if (
    $pure._state.isPending -or
    $Event.SourceEventArgs.Name -eq '.git' -or
    $Event.SourceEventArgs.Name -like '.git*.lock') { return }

  &$Global:pure._functions.updateStatus
}

