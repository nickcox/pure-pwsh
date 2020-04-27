filter fmtColor($color) { "$color$_$esc[0m" }

function global:prompt {
  $isError = !$?

  $prevGitDir = $pure._state.gitDir
  $gitDir = $pure._state.gitDir = GetGitDir
  $hasRepoChanged = $gitDir -and ($gitDir -ne $prevGitDir)

  if ($gitDir) {
    $watcher.Path = $gitDir | Split-Path # assumes .git is a subdirectory of working tree
    $watcher.EnableRaisingEvents = $true
    $Script:fetchTimer.Enabled = $pure.FetchInterval -gt 0
  }
  else {
    $watcher.EnableRaisingEvents = $false
    $Script:fetchTimer.Enabled = $false
    $pure._state.status = $Script:emptyStatus
  }

  # disptach a change event if we enetered a new repository
  if ($hasRepoChanged) { &$pure._functions.updateStatus }

  # otherwise we already have all the info we need
  $status = $pure._state.status
  $gitInfo = if ($gitDir -and !$hasRepoChanged) {
    $branchName = &$pure.BranchFormatter $status.branch
    $dirtyMark = if ($status.dirty) { "*" }
    "$branchName$dirtyMark" | fmtColor $pure._branchColor

    $remote = if ($status.behind) { $pure.downChar }
    $remote += if ($status.ahead) { $pure.upChar }

    if ($remote) { $remote | fmtColor $pure._remoteColor }
  }

  $slowInfo = if ($pure.SlowCommandTime -gt 0 -and ($lastCmd = Get-History -Count 1)) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff -gt $pure.SlowCommandTime) {
      '({0})' -f ('{0:hh\:mm\:ss\s}' -f $diff).TrimStart(':0') | fmtColor $pure._errorColor
    }
  }

  $promptColor = if ($isError) { $pure._errorColor } else { $pure._promptColor }
  $formattedPwd = &$pure.PwdFormatter $PWD.Path | fmtColor $pure._pwdColor

  (&$pure.PrePrompt $formattedPwd $gitInfo $slowInfo ) +
  ($pure.PromptChar | fmtColor $promptColor) + " "
}
