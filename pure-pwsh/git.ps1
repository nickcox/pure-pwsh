$Script:emptyStatus = [Ordered] @{
  ahead  = $false
  behind = $false
  dirty  = $false
  branch = $null
  gitDir = $null
}

function GetGitDir() {
  git rev-parse --absolute-git-dir
}

function GetGitStatus($gitDir) {
  if (!$gitDir) { return $Script:emptyStatus }

  $status = (
    git --git-dir $gitDir status -z -b
  ).Split(0, [System.StringSplitOptions]::RemoveEmptyEntries)

  $ahead = $status -match '^##.*\[ahead \d+\]?'
  $behind = $status -match '^##.*\[?behind \d+\]'
  $dirty = $status.length -gt 1
  $branch = if ($status[0] -match '^## (?<branch>[^\.]*)') { $Matches['branch'] }

  [Ordered] @{
    ahead  = !!$ahead
    behind = !!$behind
    dirty  = $dirty
    branch = $branch
    gitDir = $gitDir
  }
}
