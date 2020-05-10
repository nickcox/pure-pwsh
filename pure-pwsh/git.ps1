$Script:emptyStatus = [Ordered] @{
  ahead   = $false
  behind  = $false
  dirty   = $false
  branch  = $null
  repoDir = $null
}

function GetRepoDir() {
  git rev-parse --show-toplevel
}

function GetGitStatus($repoDir) {
  if (!$repoDir) { return $Script:emptyStatus }

  $status = (
    git -C $repoDir --no-optional-locks status -z -b
  ).Split(0, [System.StringSplitOptions]::RemoveEmptyEntries)

  $ahead = $status -match '^##.*\[ahead \d+\]?'
  $behind = $status -match '^##.*\[?behind \d+\]'
  $dirty = $status.length -gt 1
  $branch = if ($status[0] -match '^## (?<branch>[^\.]*)') { $Matches['branch'] }

  [Ordered] @{
    ahead   = !!$ahead
    behind  = !!$behind
    dirty   = $dirty
    branch  = $branch
    repoDir = $repoDir
  }
}
