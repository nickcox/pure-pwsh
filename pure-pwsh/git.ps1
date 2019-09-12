function GetRepositoryRoot() {
  iex 'git rev-parse --absolute-git-dir' -ea Ignore | split-path
}

function GetGitStatus($gitDir) {
  if (!$gitDir) { $gitDir = GetRepositoryRoot}
  if (!$gitDir) {
    return @{
      ahead  = $false
      behind = $false
      dirty  = $false
      branch = $null
      gitDir = $null
    }
  }

  $status = (
    git status -z -b
  ).Split(0, [System.StringSplitOptions]::RemoveEmptyEntries)

  $ahead = $status -match '^##.*\[ahead \d+\]'
  $behind = $status -match '^##.*\[behind \d+\]'
  $dirty = $status.length -gt 1
  $branch = if ($status[0] -match '^## (?<branch>\w*)\W') { $Matches['branch'] }

  @{
    ahead  = !!$ahead
    behind = !!$behind
    dirty  = $dirty
    branch = $branch
    gitDir = $gitDir
  }
}

$Script:emptyStatus = @{
  ahead  = $false
  behind = $false
  dirty  = $false
  branch = $null
  gitDir = $null
}

