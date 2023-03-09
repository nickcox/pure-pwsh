$Script:UpdateJob = $null

function UpdateStatus() {
  $pure._state.repoDir = GetRepoDir

  if ($pure._state.repoDir) {
    $pure._state.isPending = $true
    &$pure._functions.log "Scheduling OnIdle event"

    $Script:UpdateJob = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $Script:OnIdleCallback
  }
}

$Script:OnIdleCallback = {
  param ([bool] $isTest = $false)

  &$pure._functions.log "Running OnIdle event"
  $newStatus = &$pure._functions.getStatus $pure._state.repoDir

  if (Compare-Object $pure._state.status.values $newStatus.values) {
    &$pure._functions.log "Updating prompt.."
    $pure._state.status = $newStatus

    $isTest ? (&prompt) : [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  }
  $pure._state.isPending = $false
  Remove-Job $Script:UpdateJob
}

$Script:UpdateOnChange = {
  if (
    $pure._state.isPending -or
    $Event.SourceEventArgs.Name -match '\.git$' -or
    $Event.SourceEventArgs.Name -like '.git*.lock'
  ) { return }
  &$pure._functions.log "Change detected ($($Event.SourceEventArgs.Name))"

  &$Global:pure._functions.updateStatus
}

$Script:Fetch = {
  if ($pure._state.repoDir) {
    &$pure._functions.log "Running git fetch"
    git -C $pure._state.repoDir fetch
  }
}
