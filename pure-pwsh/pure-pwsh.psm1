. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/async.ps1

function Log($message) {
  if ((Get-Variable pure) -and ($pure | Get-Member _logger)) { &$pure._logger $message }
  else { Write-Verbose $message }
}

filter color {$_.Split('*')[0]} # the part from '*' on is only for `$pure` display

filter ??? {param ($default) if ($_) {$_} else {$default}}

$emptyStatus = @{
  HasWorking = $false
  HasIndex   = $false
  AheadBy    = 0
  BehindBy   = 0
}

function getPromptStatus($gitStatus) {
  $status = $gitStatus |??? $emptyStatus
  return [ordered]@{
    updated  = if ($gitStatus) {Get-Date} else {[DateTime]::MinValue}
    isDirty  = ($status.HasWorking -or $status.HasIndex)
    isAhead  = ($status.AheadBy -gt 0)
    isBehind = ($status.BehindBy -gt 0)
    gitDir   = $status.GitDir
  }
}

$Script:timer = New-Object System.Timers.Timer -Property @{ Interval = 1000; AutoReset = $false }
Register-ObjectEvent $timer Elapsed -Action { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }

function writePromptIfChanged() {
  $newStatus = getPromptStatus (Get-GitStatus)

  if ($promptStatus -and ($newStatus)) {
    if (
      ($newStatus.isDirty -ne $promptStatus.isDirty) -or
      ($newStatus.isAhead -ne $promptStatus.isAhead) -or
      ($newStatus.isBehind -ne $promptStatus.isBehind)) {

      Log 'updating prompt from update'
      $Script:timer.Start()
    }
  }
}

function Set-PureOption() {
  [CmdletBinding()]
  param (
    [ValidateSet(
      'PwdColor',
      'BranchColor',
      'RemoteColor',
      'ErrorColor',
      'PromptColor',
      'PromptChar',
      'UpChar',
      'DownChar')]
    $Option,

    [String]
    $Value
  )

  if ($Option -like '*Color') {
    $val = if ($Value -match '^\d*m$') {$null} else {$Value}
    $Value = valueOrDefault $val $Value
  }
  $Global:pure.$option = $value
}

function valueOrDefault($value, $default) {
  "$(if ($value) {$value} else {"$([char]27)[$default"})" +
  "*$([char]27)[0m"
}

function init() {
  $psrOptions = Get-PSReadlineOption

  if ($psrOptions) {
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'PromptText') {
      Set-PSReadLineOption -PromptText ("{0} " -f $pure.PromptChar)
    }
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ContinuationPrompt') {
      Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $pure.PromptChar)
    }

    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'Colors') {
      Set-PSReadLineOption -Colors @{ ContinuationPrompt = $psrOptions.EmphasisColor }
    }

    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ExtraPromptLineCount') {
      Set-PSReadLineOption -ExtraPromptLineCount 2
    }
  }
}

$Global:pure = [ordered]@{
  PwdColor             = valueOrDefault $psrOptions.CommentColor "32m"
  BranchColor          = valueOrDefault $psrOptions.StringColor "36m"
  RemoteColor          = valueOrDefault $psrOptions.TypeColor "37m"
  ErrorColor           = valueOrDefault $psrOptions.ErrorColor "91m"
  PromptColor          = valueOrDefault $psrOptions.EmphasisColor "96m"
  PromptChar           = '❯'
  UpChar               = '⇡'
  DownChar             = '⇣'
  SlowCommandThreshold = [timespan]::FromSeconds(5)
  FetchPeriod          = [timespan]::FromSeconds(300)
  Debounce             = [timespan]::FromSeconds(1)
}

$Script:promptStatus = getPromptStatus $emptyStatus

$Script:watcher = [IO.FileSystemWatcher]::new()
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true

function registerWatcherEvent($eventName) {
  Register-ObjectEvent -InputObject $watcher -EventName $eventName -Action $updateOnChange -MessageData @{
    getNewStatus         = {getPromptStatus (& {Get-GitStatus})}
    currentStatus        = {$promptStatus}
    log                  = {Log @args}
    writePromptIfChanged = {writePromptIfChanged}
    toggleWatcher        = {$watcher.EnableRaisingEvents = $args[0] }
  }
}

$null = registerWatcherEvent Changed
$null = registerWatcherEvent Deleted

init