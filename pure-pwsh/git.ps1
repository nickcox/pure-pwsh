function GetGitDir() {
  iex 'git rev-parse --absolute-git-dir'
}

function GetGitStatus($gitDir) {
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
    git --git-dir $gitDir status -z -b
  ).Split(0, [System.StringSplitOptions]::RemoveEmptyEntries)

  $ahead = $status -match '^##.*\[ahead \d+\]'
  $behind = $status -match '^##.*\[behind \d+\]'
  $dirty = $status.length -gt 1
  $branch = if ($status[0] -match '^## (?<branch>\w*)') { $Matches['branch'] }

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

