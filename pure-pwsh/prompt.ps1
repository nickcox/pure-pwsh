filter fmtColor($color) { "$color$_$esc[0m" }

function global:prompt {
  $isError = !$?

  $gitDir = $pure._state.gitDir = GetGitDir

  if ($gitDir) {
    $watcher.Path = $gitDir | Split-Path
    $watcher.EnableRaisingEvents = $true
  }
  else {
    $watcher.EnableRaisingEvents = $false
  }

  $status = $pure._state.status
  $hasRepoChanged = $gitDir -and ($gitDir -ne $status.gitDir)

  if ($hasRepoChanged) { UpdateStatus }

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

  (
    (&$pure.PrePrompt $formattedPwd $gitInfo $slowInfo ) +
    ($pure.PromptChar | fmtColor $promptColor) + " "
  ) -replace ' +', ' '
}
