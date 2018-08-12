function asyncGitFetch() {
  if ($gitStatus = Get-GitStatus) {

    if (Get-Job Pure__* | Where PSBeginTime -ge ((Get-Date).AddSeconds(-30))) {
      return
    }

    else {
      Get-Job Pure__* | Where State -eq Completed | Remove-Job
      Get-Job Pure__* | Where State -eq Stopped   | Remove-Job
    }

    # get the before fetch state
    $currentHead = Get-Content "$($gitStatus.GitDir)/FETCH_HEAD"

    $null = Start-Job -Name "Pure__GitFetch"-ScriptBlock {
      param($gitDir, $currentHead)

      git -C $gitDir fetch;

      $newHead = Get-Content "$gitDir/FETCH_HEAD"
      $newHead -and ($newHead -ne $currentHead)
    } -ArgumentList $gitStatus.GitDir, $currentHead
  }
}

$Script:UpdateOnChange = {
  $state = $event.MessageData
  $currentStatus = &($state.getCurrentStatus)

  if (!$currentStatus.gitDir) {return}
  if ($Event.SourceEventArgs.Name -eq '.git') {return}

  $mutex = [System.Threading.Mutex]::new($false, ('pure__' + $currentStatus.gitDir -replace '[^\w]' , ''))
  if (!$mutex.WaitOne(0)) {
    &$state.log 'mutex unavailable'
    return
  }

  try {

    $debounce = $pure.Debounce

    $timeSinceUpdate = (Get-Date) - $currentStatus.updated

    if ($timeSinceUpdate -le $debounce) {
      &$state.log "Debounce not cleared ($debounce >= $timeSinceUpdate)."
      return
    }

    &$state.log "Debounce clear ($debounce)."
    &$state.log "$($event.SourceEventArgs | ConvertTo-Json -Compress)"

    Split-Path -Parent $currentStatus.gitDir | Push-Location

    $newStatus = &$state.getNewStatus

    &$state.log "new status: "
    &$state.log "$($newStatus | ConvertTo-Json | ConvertTo-Json -Compress)"

    &$state.log "old status: "
    &$state.log "$($currentStatus | ConvertTo-Json | ConvertTo-Json -Compress)"

    if ($currentStatus -and ($newStatus)) {
      if (
        ($newStatus.isDirty -ne $promptStatus.isDirty) -or
        ($newStatus.isAhead -ne $promptStatus.isAhead) -or
        ($newStatus.isBehind -ne $promptStatus.isBehind)) {

        &$state.log 'updating prompt from update'
        [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
      }
    }
  }
  finally {
    $mutex.ReleaseMutex()
  }
}