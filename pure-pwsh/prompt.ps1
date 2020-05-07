filter fmtColor($color) { "$color$_$esc[0m" }

function global:prompt {
  $isError = !$?

  $prevrepoDir = $pure._state.repoDir
  $repoDir = $pure._state.repoDir = GetrepoDir
  $hasRepoChanged = $repoDir -and ($repoDir -ne $prevrepoDir)

  if ($repoDir) {
    $watcher.Path = $repoDir
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
  $gitInfo = if ($repoDir -and !$hasRepoChanged) {
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
  $formattedUser = &$pure.UserFormatter $env:SSH_CONNECTION $env:USERNAME ([System.Net.Dns]::GetHostName()) | fmtColor $pure._branchColor

  (&$pure.PrePrompt $formattedUser $formattedPwd $gitInfo $slowInfo ) +
  ($pure.PromptChar | fmtColor $promptColor) + " "
}
