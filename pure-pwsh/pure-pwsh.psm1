. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/options.ps1

$esc = [char]27

initOptions

Import-Module $PSScriptRoot/bin/PurePwsh.dll
$Script:watcher = [PurePwsh.Watcher]::new($pwd, $pure.FetchInterval.TotalMilliseconds)

Register-ObjectEvent $watcher LogEvent -Action { Write-Verbose $eventargs.Output }
Register-ObjectEvent $watcher StatusChanged -Action { 
  try {
    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
  } catch {
    # meh...
  }
}