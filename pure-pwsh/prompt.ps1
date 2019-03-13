filter fmtColor($color) {"$color$_$esc[0m"}

function global:prompt {
  $isError = !$?

  ($gitPath = $watcher.Status.GitPath) -and ($repoPath = $gitPath | Split-Path) | out-null
  $hasRepoChanged = $gitPath -and !($PWD.Path -like "$($repoPath)*")
  if (!$gitPath -or $hasRepoChanged) { $watcher.PwdChanged($PWD) | out-null }

  $gitInfo = if ($gitPath -and !$hasRepoChanged) {

    $branchName = &$pure.BranchFormatter $watcher.Status.BranchName
    $dirtyMark = if ($watcher.Status.Dirty) { "*" }
    "$branchName$dirtyMark" | fmtColor $pure._branchColor

    $remote = if ($watcher.Status.Behind) { $pure.downChar }
    $remote += if ($watcher.Status.Ahead) { $pure.upChar }
    $remote | fmtColor $pure._remoteColor
  }

  $slowInfo = if ($lastCmd = Get-History -Count 1) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff -gt $pure.SlowCommandTime) {
      "($("{0:f2}" -f $diff.TotalSeconds)s)" | fmtColor $pure._errorColor
    }
  }

  $promptColor = if ($isError) {$pure._errorColor} else {$pure._promptColor}
  $formattedPwd = &$pure.PwdFormatter $PWD.Path | fmtColor $pure._pwdColor

  "`n$(&$pure.PrePrompt $formattedPwd $gitInfo $slowInfo)" +
  "`n$($pure.PromptChar | fmtColor $promptColor) "
}