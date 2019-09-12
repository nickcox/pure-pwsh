filter fmtColor($color) { "$color$_$esc[0m" }

function global:prompt {
  $isError = !$?

  $status = $pure._state.status
  $status.gitDir -and ($repoPath = $status.gitDir | Split-Path) | Out-Null
  $hasRepoChanged = $status.gitDir -and !($PWD.Path -like "$($repoPath)*")

  if (!$status.gitDir -or $hasRepoChanged) { UpdateStatus }

  $gitInfo = if ($status.gitDir -and !$hasRepoChanged) {
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