Class Pure {
  static hidden [string] ansiSequence([string] $value) {
    return ($Value -match "`e") ? $Value : "`e[${Value}m"
  }

  static hidden [timespan] timespan($value) {
    return ($value -is [Int]) ? [timespan]::FromSeconds($value) : [timespan]$value
  }

  hidden [char] $_promptChar = '❯'
  hidden [string] $_pwdColor = [Pure]::ansiSequence('34')
  hidden [string] $_branchColor = [Pure]::ansiSequence('38;5;242')
  hidden [string] $_dirtyColor = [Pure]::ansiSequence('38;5;218')
  hidden [string] $_remoteColor = [Pure]::ansiSequence('36')
  hidden [string] $_errorColor = [Pure]::ansiSequence('31')
  hidden [string] $_promptColor = [Pure]::ansiSequence('35')
  hidden [string] $_timeColor = [Pure]::ansiSequence('33')
  hidden [string] $_userColor = [Pure]::ansiSequence('38;5;242')
  hidden [timespan] $_fetchInterval = [timespan]::FromMinutes(5)
  hidden [timespan] $_slowCommandTime = [timespan]::FromSeconds(10)
  hidden [scriptblock] $_prePrompt = { param ($user, $cwd, $git, $slow) "`n$user{0}$cwd $git $slow `n" -f ($user ? ' ' : '') }
  hidden [hashtable] $_state = @{ isPending = $false; status = $emptyStatus; repoDir = '' }
  hidden [hashtable] $_functions = @{
    log          = { Write-Verbose $args[0] };
    getStatus    = { GetGitStatus $args[0] }
    updateStatus = { UpdateStatus }
  }

  [char] $UpChar = '⇡'
  [char] $DownChar = '⇣'
  [char] $PendingChar = '⋯'
  [scriptblock] $BranchFormatter = { $args }
  [scriptblock] $PwdFormatter = { $args.Replace($HOME, '~') }
  [scriptblock] $UserFormatter = { param ($isSsh, $user, $hostname) $isSsh ? "$user@$hostname" : '' }
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

  hidden [void] addColorProperty([string] $shortName) {
    $name = "${shortName}Color"
    $this | Add-Member -Name $name -MemberType ScriptProperty -Value {
      $this."_$name" + "*`e[0m" # coloured asterisk for display purposes
    }.GetNewClosure() -SecondValue {
      param([string] $value)
      $this."_$name" = [pure]::ansiSequence($value)
      $this.updatePSReadLine()
    }.GetNewClosure()
  }

  Pure() {
    @('Pwd', 'Branch', 'Dirty', 'Remote', 'Error', 'Prompt', 'Time', 'User') | ForEach-Object {
      $this.addColorProperty($_)
    }

    $this | Add-Member -Name SlowCommandTime -MemberType ScriptProperty -Value {
      $this._slowCommandTime
    } -SecondValue { $this._slowCommandTime = [Pure]::timespan($args[0]) }

    $this | Add-Member -Name FetchInterval -MemberType ScriptProperty -Value {
      $this._fetchInterval
    } -SecondValue {
      param($value)

      $timespan = [Pure]::timespan($value)

      if ($timespan -eq 0) {
        $Script:fetchTimer.Enabled = $false
        $this._fetchInterval = $timespan
        return
      }

      if ($timespan -lt [timespan]::FromSeconds(30)) {
        throw "Minimum fetch interval is 30s. (0 to disable.)"
      }

      $Script:fetchTimer.Interval = $timespan.TotalMilliseconds
      $Script:fetchTimer.Enabled = $true

      $this._fetchInterval = $timespan
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
