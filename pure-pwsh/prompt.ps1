function global:prompt {
  $isError = !$?
  $Script:timer.Stop() # if we have a pending redraw, cancel it now

  $startTime = Get-Date

  $hasRepoChanged = !($PWD.Path -eq $watcher.Path -or (
      $watcher.EnableRaisingEvents -and ($PWD.Path -like "$($watcher.Path)*")))

  $curPath = $PWD.Path
  if ($curPath.ToLower().StartsWith($Home.ToLower())) {
    $curPath = "~" + $curPath.SubString($Home.Length)
  }

  $prompt = "`n"
  $prompt += "$curPath " | fmtColor $pure.pwdColor

  if (!$hasRepoChanged -and $promptStatus.gitDir -or (
      $gitStatus = if ($null -ne (Get-Module posh-git)) {get-gitstatus} else {$null})) {

    if ($hasRepoChanged -or !$watcher.EnableRaisingEvents) {
      Log 'Updating watched repo'
      $watcher.Path = git rev-parse --show-toplevel | Resolve-Path
      $watcher.EnableRaisingEvents = $true
      $Script:promptStatus = getPromptStatus $gitStatus
    }

    if ($pure.FetchPeriod -gt 0) { asyncGitFetch }

    $dirtyMark = if ($promptStatus.isDirty) { "*" } else { "" }
    $prompt += ($promptStatus.branch + $dirtyMark) | fmtColor $pure.branchColor
    $prompt += " "

    if ($promptStatus.isBehind) {
      $prompt += $pure.downChar | fmtColor $pure.remoteColor
    }

    if ($promptStatus.isAhead) {
      $prompt += $pure.upChar | fmtColor $pure.remoteColor
    }
  }

  else {
    $watcher.Path = $PWD
    $watcher.EnableRaisingEvents = $false
    $Script:promptStatus = getPromptStatus $null
  }

  if ($lastCmd = Get-History -Count 1) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff -gt $pure.SlowCommandTime) {
      $prompt += " ($("{0:f2}" -f $diff.TotalSeconds)s)" | fmtColor $pure.errorColor
    }
  }

  $promptColor = if ($isError) {$pure.errorColor} else {$pure.PromptColor}
  $prompt += "`n"
  $prompt += "`n$($pure.PromptChar) " | fmtColor $promptColor
  $prompt

  $endTime = (Get-Date) - $startTime
  Log $endTime.TotalMilliseconds
}

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
    branch   = $status.Branch
  }
}