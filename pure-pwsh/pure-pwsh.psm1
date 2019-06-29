. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/options.ps1

$Script:esc = [char]27

initOptions

Import-Module $PSScriptRoot/bin/PurePwsh.dll
$Script:watcher = [PurePwsh.Watcher]::new($pwd, $pure.FetchInterval.TotalMilliseconds)
$Global:pure._state.watcherCallback = { $watcher.UpdateGitStatus() }

Register-ObjectEvent $watcher LogEvent -Action { &$Global:pure._log $eventargs.Output }
Register-ObjectEvent $watcher StatusChanged -Action { 
  if ($Global:pure._state.isPending) { return }
  $Global:pure._state.isPending = $true 

  Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
    $task = &$Global:pure._state.watcherCallback
    while (-not $task.AsyncWaitHandle.WaitOne(200)) { }
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
    $Global:pure._state.isPending = $false
  }
}