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
  hidden [char]   $_promptChar = '❯'

  [timespan] $SlowCommandTime = ([timespan]::FromSeconds(5))
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
      if ($name -eq 'PromptColor') {
        if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ContinuationPromptColor') {
          Set-PSReadLineOption -Colors @{ ContinuationPrompt = $this._PromptColor }
        }
      }
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

    $this | Add-Member -Name PromptChar -MemberType ScriptProperty -Value {
      $this._promptChar
    } -SecondValue {
      param([char] $value)
      $this._promptChar = $value
      if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ContinuationPrompt') {
        Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $value)
      }
    }
  }
}

function initOptions() {

  $Global:pure = New-Object Pure
  $psrOptions = Get-PSReadlineOption

  if ($psrOptions) {
    if ((Get-PSReadLineOption).PSObject.Properties.Name -notcontains 'PromptText') {
      # PSReadLine < 2.0 seems to mangle the preferred characters on redraw
      $pure.PromptChar = '→'
      $pure.UpChar = '↑'
      $pure.DownChar = '↓'
    }

    if ((Get-PSReadLineOption).PSObject.Properties.Name -contains 'ExtraPromptLineCount') {
      $extraLines = $pure.PrePrompt.ToString().Split("``n").Length - 1
      Set-PSReadLineOption -ExtraPromptLineCount $extraLines
    }
  }

  $Global:pure.PromptChar = $pure._promptChar
  $Global:pure.PromptColor = $pure._promptColor
}