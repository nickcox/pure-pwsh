function UpdateStatus() {
  $pure._state.gitDir = GetGitDir

  if ($pure._state.gitDir) {
    $pure._state.isPending = $true
    &$pure._functions.log "Scheduling OnIdle event"

    $null = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $OnIdleCallback
  }
}

$Script:OnIdleCallback = {
  param ([bool] $isTest = $false)

  &$pure._functions.log "Running OnIdle event"
  $newStatus = &$pure._functions.getStatus $pure._state.gitDir

  if (Compare-Object $pure._state.status.values $newStatus.values) {
    &$pure._functions.log "Prompt will update..."
    $pure._state.status = $newStatus

    $isTest ? (&prompt) : [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }
  $pure._state.isPending = $false
}

$Script:UpdateOnChange = {
  if (
    $pure._state.isPending -or
    $Event.SourceEventArgs.Name -eq '.git' -or
    $Event.SourceEventArgs.Name -like '.git*.lock'
  ) { return }
  &$pure._functions.log "Change detected ($($Event.SourceEventArgs.Name))"

  &$Global:pure._functions.updateStatus
}

$Script:Fetch = {
  if ($pure._state.gitDir) {
    &$pure._functions.log "git fetch"
    git -C $pure._state.gitDir fetch
  }
}
