filter fmtColor($color) { "$color$_$esc[0m" }

function global:prompt {
  $isError = !$?

  ($gitPath = $watcher.Status.GitPath) -and ($repoPath = $gitPath | Split-Path) | Out-Null
  $hasRepoChanged = $gitPath -and !($PWD.Path -like "$($repoPath)*")
  if (!$gitPath -or $hasRepoChanged) { $watcher.PwdChanged($PWD) | Out-Null }

  $gitInfo = if ($gitPath -and !$hasRepoChanged) {
    $branchName = &$pure.BranchFormatter $watcher.Status.BranchName
    $dirtyMark = if ($watcher.Status.Dirty) { "*" }
    "$branchName$dirtyMark" | fmtColor $pure._branchColor

    $remote = if ($watcher.Status.Behind) { $pure.downChar }
    $remote += if ($watcher.Status.Ahead) { $pure.upChar }

    if ($remote) { $remote | fmtColor $pure._remoteColor }
  }
  
  $slowInfo = if ($pure.SlowCommandTime -gt 0 -and ($lastCmd = Get-History -Count 1)) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff -gt $pure.SlowCommandTime) {
      "($("{0:f2}" -f $diff.TotalSeconds)s) " | fmtColor $pure._errorColor
    }
  }

  $promptColor = if ($isError) { $pure._errorColor } else { $pure._promptColor }
  $formattedPwd = &$pure.PwdFormatter $PWD.Path | fmtColor $pure._pwdColor

  (
    (&$pure.PrePrompt $formattedPwd $gitInfo $slowInfo ) +
    ($pure.PromptChar | fmtColor $promptColor) + " "
  ) -replace ' +', ' '
}