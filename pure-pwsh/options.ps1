function Set-PureOption() {
  [CmdletBinding()]
  param (
    [ValidateSet(
      'PwdColor',
      'BranchColor',
      'RemoteColor',
      'ErrorColor',
      'PromptColor',
      'PromptChar',
      'UpChar',
      'DownChar')]
    $Option,

    [String]
    $Value
  )

  if ($Option -like '*Color') {
    $Global:pure.$option = (ansiSequence $Value)
  }
  else {
    $Global:pure.$option = $Value
  }
}

function ansiSequence([string] $value) {
  $(if ($value.Contains($esc)) {$value} else {"$esc[$value"}) +
  "*$esc[0m" # append an asterisk and reset the colour for display purposes
}

function initOptions() {
  $psrOptions = Get-PSReadlineOption

  if ($psrOptions) {
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'PromptText') {
      Set-PSReadLineOption -PromptText ("{0} " -f $pure.PromptChar)
    }
    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ContinuationPrompt') {
      Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $pure.PromptChar)
    }

    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'Colors') {
      Set-PSReadLineOption -Colors @{ ContinuationPrompt = $psrOptions.EmphasisColor }
    }

    if ((Get-PSReadlineOption).PSObject.Properties.Name -contains 'ExtraPromptLineCount') {
      Set-PSReadLineOption -ExtraPromptLineCount 2
    }
  }

  $Global:pure = New-Object PSObject -Property (
    [ordered]@{
      PwdColor        = ansiSequence ($psrOptions.CommentColor |??? "32m")
      BranchColor     = ansiSequence ($psrOptions.StringColor |??? "36m")
      RemoteColor     = ansiSequence ($psrOptions.OperatorColor |??? "37m")
      ErrorColor      = ansiSequence ($psrOptions.ErrorColor |??? "91m")
      PromptColor     = ansiSequence ($psrOptions.EmphasisColor |??? "96m")
      PromptChar      = '❯'
      UpChar          = '⇡'
      DownChar        = '⇣'
      SlowCommandTime = [timespan]::FromSeconds(5.0)
      FetchPeriod     = [timespan]::FromSeconds(300)
      Debounce        = [timespan]::FromSeconds(0.5)
    })
}