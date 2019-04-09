function ansiSequence([string] $Value) {
  if ($Value.Contains($esc)) {$Value} else {"$esc[$Value"}
}

Class Pure {
  static hidden [char] $esc = $esc
  static hidden [string] ansiSequence([string] $value) {
    return ansiSequence $value
  }
  
  hidden [string] $_pwdColor = (ansiSequence "34m")
  hidden [string] $_branchColor = (ansiSequence "90m")
  hidden [string] $_remoteColor = (ansiSequence "36m")
  hidden [string] $_errorColor = (ansiSequence "91m")
  hidden [string] $_promptColor = (ansiSequence "35m")
  hidden [string] $_fetchInterval = ([timespan]::FromMinutes(5))

  [timespan] $SlowCommandTime = ([timespan]::FromSeconds(5))
  [char] $PromptChar = '❯'
  [char] $UpChar = '⇡'
  [char] $DownChar = '⇣'
  [scriptblock] $BranchFormatter = {$args}
  [scriptblock] $PwdFormatter = {$args.Replace($HOME, '~')}
  [scriptblock] $PrePrompt = {param ($cwd, $git, $slow) "`n$cwd $git $slow`n"}

  hidden addColorProperty([string] $name) {
    $this | Add-Member -Name $name -MemberType ScriptProperty -Value {
      $this."_$name" + "⬛$([pure]::esc)[0m" # pretty it up for `$pure` display purposes
    }.GetNewClosure() -SecondValue {
      param([string] $value)
      $this."_$name" = [pure]::ansiSequence($value)
    }.GetNewClosure()
  }

  Pure() {
    @('PwdColor', 'BranchColor', 'RemoteColor', 'ErrorColor', 'PromptColor') | % {
      $this.addColorProperty($_)
    }

    $this | Add-Member -Name FetchInterval -MemberType ScriptProperty -Value {
      $this._fetchInterval
    } -SecondValue {
      param([timespan] $value)
      if ($value -lt [timespan]::FromSeconds(30)) { 
        throw "Minimum fetch interval is 30s."
      }
      $Script:watcher.GitFetchMs = $Value.TotalMilliseconds
      $this._fetchInterval = $value
    }
  }
}

function initOptions() {

  $Global:pure = New-Object Pure
  $psrOptions = Get-PSReadlineOption

  if ($psrOptions) {
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'PromptText') {
      # Set-PSReadLineOption -PromptText ("{0} " -f $pure.PromptChar)
    }
    else {
      # PSReadLine < 2.0 seems to mangle the preferred characters on redraw
      $pure.PromptChar = '→'
      $pure.UpChar = '↑'
      $pure.DownChar = '↓'
    }
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ContinuationPrompt') {
      Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $pure.PromptChar)
    }

    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'Colors') {
      Set-PSReadLineOption -Colors @{ ContinuationPrompt = $pure.PromptColor }
    }

    if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ExtraPromptLineCount') {
      $extraLines = $pure.PrePrompt.ToString().Split("``n").Length - 1
      Set-PSReadLineOption -ExtraPromptLineCount $extraLines
    }
  }
}