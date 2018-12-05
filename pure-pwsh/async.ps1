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
      Where {$_.State -eq 'Completed' -or $_.State -eq 'Stopped'} |
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

$Script:UpdateOnChange = {
  if (
    $Event.SourceEventArgs.Name -eq '.git' -or
    $Event.SourceEventArgs.Name -like '.git*.lock') {return}

  $state = $event.MessageData
  &$state.maybeDirty = $true

  $currentStatus = &$state.currentStatus
  if (!$currentStatus.gitDir) {return} # not a git directory

  $timeSinceUpdate = (Get-Date) - $currentStatus.updated
  if ($timeSinceUpdate.TotalMilliseconds -le (&$state.backoff)) {
    return
  }

  &$state.log "$($event.SourceEventArgs | ConvertTo-Json -Compress)"
  &$state.writePromptIfChanged
}

function writePromptIfChanged() {
  $Script:backoff = [Math]::Min($Script:backoff * 2, 10000)
  $Script:promptStatus.updated = Get-Date
  $newStatus = getPromptStatus (Get-GitStatus)

  if ($promptStatus -and ($newStatus)) {
    if (
      ($newStatus.isDirty -ne $promptStatus.isDirty) -or
      ($newStatus.isAhead -ne $promptStatus.isAhead) -or
      ($newStatus.isBehind -ne $promptStatus.isBehind)) {

      Log 'updating prompt'
      $Script:promptStatus = $newStatus
      $Script:maybeDirty = $false
      $Script:timer.Start()
    }
  }
}