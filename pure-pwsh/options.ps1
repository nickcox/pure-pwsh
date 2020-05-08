Class Pure {
  static hidden [string] ansiSequence([string] $value) {
    return ($Value -match "`e") ? $Value : "`e[${Value}m"
  }

  hidden [char] $_promptChar = '❯'
  hidden [string] $_pwdColor = [Pure]::ansiSequence('34')
  hidden [string] $_branchColor = [Pure]::ansiSequence('90')
  hidden [string] $_remoteColor = [Pure]::ansiSequence('36')
  hidden [string] $_errorColor = [Pure]::ansiSequence('91')
  hidden [string] $_promptColor = [Pure]::ansiSequence('35')
  hidden [timespan] $_fetchInterval = ([timespan]::FromMinutes(5))
  hidden [scriptblock] $_prePrompt = { param ($user, $cwd, $git, $slow) "`n$user$cwd $git $slow `n" }
  hidden [hashtable] $_state = @{ isPending = $false; status = $emptyStatus; repoDir = '' }
  hidden [hashtable] $_functions = @{
    log          = { Write-Verbose $args[0] };
    getStatus    = { GetGitStatus $args[0] }
    updateStatus = { UpdateStatus }
  }

  [char] $UpChar = '⇡'
  [char] $DownChar = '⇣'
  [char] $PendingChar = '⋯'
  [timespan] $SlowCommandTime = ([timespan]::FromSeconds(10))
  [scriptblock] $BranchFormatter = { $args }
  [scriptblock] $PwdFormatter = { $args.Replace($HOME, '~') }
  [scriptblock] $UserFormatter = { param ($isSsh, $user, $hostname) $isSsh ? "$user@$hostname " : "" }
  [scriptblock] $WindowTitle = { $PWD.Path.Replace($HOME, '~') }

  hidden [void] updatePSReadLine() {
    if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ExtraPromptLineCount') {
      $extraLines = $this._prePrompt.ToString().Split("``n").Length - 1
      Set-PSReadLineOption -ExtraPromptLineCount $extraLines
    }

    if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ContinuationPrompt') {
      Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $this._promptChar)
    }

    if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ContinuationPromptColor') {
      Set-PSReadLineOption -Colors @{ ContinuationPrompt = $this._promptColor }
    }
  }

  hidden [void] addColorProperty([string] $name) {
    $this | Add-Member -Name $name -MemberType ScriptProperty -Value {
      $this."_$name" + "*`e[0m" # coloured asterisk for display purposes
    }.GetNewClosure() -SecondValue {
      param([string] $value)
      $this."_$name" = [pure]::ansiSequence($value)
      $this.updatePSReadLine()
    }.GetNewClosure()
  }

  Pure() {
    @('PwdColor', 'BranchColor', 'RemoteColor', 'ErrorColor', 'PromptColor') | ForEach-Object {
      $this.addColorProperty($_)
    }

    $this | Add-Member -Name FetchInterval -MemberType ScriptProperty -Value {
      $this._fetchInterval
    } -SecondValue {
      param($input)

      $value = ($input -is [Int])
        ? [timespan]::FromSeconds($value)
        : [timespan]$value

      if ($value -eq 0) {
        $Script:fetchTimer.Enabled = $false
        $this._fetchInterval = $value
        return
      }

      if ($value -lt [timespan]::FromSeconds(30)) {
        throw "Minimum fetch interval is 30s. (0 to disable.)"
      }

      $Script:fetchTimer.Interval = $value.TotalMilliseconds
      $Script:fetchTimer.Enabled = $true

      $this._fetchInterval = $value
    }

    $this | Add-Member -Name PrePrompt -MemberType ScriptProperty -Value {
      $this._prePrompt
    } -SecondValue {
      param([scriptblock] $value)
      $this._prePrompt = $value
      $this.updatePSReadLine()
    }

    $this | Add-Member -Name PromptChar -MemberType ScriptProperty -Value {
      $this._promptChar
    } -SecondValue {
      param([char] $value)
      $this._promptChar = $value
      $this.updatePSReadLine()
    }
  }
}

function initOptions() {
  $Global:pure = New-Object Pure
  $Global:pure.updatePSReadLine()
}
