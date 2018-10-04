function global:prompt {
  $isError = !$?
  $Script:timer.Stop() # if we have a pending redraw, cancel it now

  $startTime = Get-Date

  $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  if ($curPath.ToLower().StartsWith($Home.ToLower())) {
    $curPath = "~" + $curPath.SubString($Home.Length)
  }

  $prompt = "`n{0}$curPath " -f ($pure.pwdColor | color)

  if (
    $promptStatus.isAsync -or
    ($gitStatus = if ($null -ne (Get-Module posh-git)) {get-gitstatus} else {$null})
  ) {

    if ($promptStatus.repoChanged) {
      $watcher.Path = git rev-parse --show-toplevel
      $watcher.EnableRaisingEvents = $true
    }

    if ($pure.FetchPeriod -gt 0) { asyncGitFetch }

    if (!$promptStatus.isAsync) {
      $Script:promptStatus = getPromptStatus $gitStatus
    }
    $prompt += "{0}$($gitStatus.branch)" -f $($pure.branchColor | color)
    if ($promptStatus.isDirty) {
      $prompt += "*"
    }
    $prompt += " "
    if ($promptStatus.isBehind) {
      $prompt += "{0}$($pure.downChar)" -f ($pure.remoteColor | color)
    }

    if ($promptStatus.isAhead) {
      $prompt += "{0}$($pure.upChar)" -f ($pure.remoteColor | color)
    }
  }

  else {
    $watcher.EnableRaisingEvents = $false
  }

  if ($lastCmd = Get-History -Count 1) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff -gt $pure.SlowCommandThreshold) {
      $prompt += "{0} ($("{0:f2}" -f $diff.TotalSeconds)s)" -f ($pure.errorColor | color)
    }
  }

  $promptColor = if ($isError) {$pure.errorColor} else {$pure.PromptColor}
  $prompt += "`n{0}$($pure.PromptChar) " -f ($promptColor | color)
  $prompt

  $endTime = (Get-Date) - $startTime
  Log $endTime.TotalMilliseconds
}