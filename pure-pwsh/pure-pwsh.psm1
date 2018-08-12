. $PSScriptRoot/prompt.ps1
. $PSScriptRoot/async.ps1

$Global:log = @('')

function Log($message) {
  $Global:log += "{0}: {1}" -f (Get-Date).TimeOfDay, $message
}

Log "Starting..."

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
    Set-PSReadLineOption -PromptText ("{0} " -f $pure.PromptChar)
    Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $pure.PromptChar)
    Set-PSReadLineOption -Colors @{ ContinuationPrompt = $psrOptions.EmphasisColor }
    Set-PSReadLineOption -ExtraPromptLineCount 2
  }
}

$Global:pure = [ordered]@{
  PwdColor    = valueOrDefault $psrOptions.CommentColor "32m"
  BranchColor = valueOrDefault $psrOptions.StringColor "36m"
  RemoteColor = valueOrDefault $psrOptions.TypeColor "37m"
  ErrorColor  = valueOrDefault $psrOptions.ErrorColor "91m"
  PromptColor = valueOrDefault $psrOptions.EmphasisColor "96m"
  PromptChar  = '❯'
  UpChar      = '⇡'
  DownChar    = '⇣'
  Debounce    = [timespan]::FromSeconds(2)
  FetchPeriod = [timespan]::FromSeconds(300)
}

$Global:promptStatus = getPromptStatus $emptyStatus

$Global:watcher = [IO.FileSystemWatcher]::new()
$watcher.Path = (Get-Location).Path
$watcher.IncludeSubdirectories = $true

$Script:watchEvent = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $updateOnChange -MessageData @{
  getNewStatus     = {getPromptStatus (& {Get-GitStatus})}
  getCurrentStatus = {$Global:promptStatus}
  log              = {Log @args}
}
init