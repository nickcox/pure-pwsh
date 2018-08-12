function global:prompt {
  $isError = !$?

  $watcher.Path = $PWD
  asyncGitFetch

  $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  if ($curPath.ToLower().StartsWith($Home.ToLower())) {
    $curPath = "~" + $curPath.SubString($Home.Length)
  }

  $prompt = "`n$($pure.pwdColor | color)$curPath "

  $gitStatus = if ($null -ne (Get-Module posh-git)) {get-gitstatus} else {$null}
  if ($gitStatus) {
    $Global:promptStatus = getPromptStatus $gitStatus
    $prompt += "$($pure.branchColor | color)$($gitStatus.branch)"
    if ($promptStatus.isDirty) {
      $prompt += "*"
    }
    $prompt += " "
    if ($promptStatus.isBehind) {
      $prompt += "$($pure.remoteColor | color)$($pure.downChar)"
    }

    if ($promptStatus.isAhead) {
      $prompt += "$($pure.remoteColor | color)$($pure.upChar)"
    }
  }

  if ($lastCmd = Get-History -Count 1) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff.TotalSeconds -gt 2) {
      $prompt += "$($pure.errorColor | color) ($("{0:f2}" -f $diff.TotalSeconds)s)"
    }
  }

  $promptColor = if ($isError) {$pure.errorColor} else {$pure.PromptColor}
  $prompt += "`n$($promptColor | color)$($pure.PromptChar) "
  $prompt
}