. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/async.ps1
. $PSScriptRoot/options.ps1

$esc = [char]27

# the part of `color` after the '*' is only to make it look nice in `$pure`
filter fmtColor($color) {$color.Split('*')[0] + $_ + "$esc[0m"}

filter ???($default) {if ($_) {$_} else {$default}}

function Log($message) {
  if ((Get-Variable pure) -and ($pure | Get-Member _logger)) { &$pure._logger $message }
  else { Write-Verbose $message }
}

function registerWatcherEvent($eventName) {
  Register-ObjectEvent -InputObject $watcher -EventName $eventName -Action $updateOnChange -MessageData @{
    log                  = {Log @args}
    currentStatus        = {$promptStatus}
    writePromptIfChanged = {writePromptIfChanged}
    toggleWatcher        = {$watcher.EnableRaisingEvents = $args[0]}
    backoff              = {$Script:backoff}
  }
}

$Script:timer = New-Object System.Timers.Timer -Property @{ Interval = 1000; AutoReset = $false }
Register-ObjectEvent $timer Elapsed -Action { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }

$Global:watcher = [IO.FileSystemWatcher]::new()
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true

$null = registerWatcherEvent Changed
$null = registerWatcherEvent Deleted

initOptions
$Script:promptStatus = getPromptStatus $emptyStatus
$Script:backoff = $pure.Debounce