. $PSScriptRoot/git.ps1
. $PSScriptRoot/async.ps1
. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/options.ps1

initOptions

function registerWatcherEvent($eventName) {
  Register-ObjectEvent -InputObject $watcher -EventName $eventName -Action $UpdateOnChange
}

$Script:watcher = [IO.FileSystemWatcher]::new()
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true

$Script:fetchTimer = [System.Timers.Timer]::new($pure.FetchInterval.TotalMilliseconds)
Register-ObjectEvent -InputObject $Script:fetchTimer -EventName Elapsed -Action $Fetch

$null = registerWatcherEvent Changed
$null = registerWatcherEvent Deleted
