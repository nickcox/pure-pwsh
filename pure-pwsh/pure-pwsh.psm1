. $PSScriptRoot/git.ps1
. $PSScriptRoot/async.ps1
. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/options.ps1

$Script:esc = [char]27

initOptions

function registerWatcherEvent($eventName) {
  Register-ObjectEvent -InputObject $watcher -EventName $eventName -Action $updateOnChange
}

UpdateStatus
$Global:watcher = [IO.FileSystemWatcher]::new()
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true

$null = registerWatcherEvent Changed
$null = registerWatcherEvent Deleted