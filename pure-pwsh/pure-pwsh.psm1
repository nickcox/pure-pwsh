$Global:log = @('Started')

filter color {$_.Split('*')[0]} # the part from '*' is only for `$pure` display

function asyncGitFetch() {
  if ($gitStatus = Get-GitStatus) {

    if (Get-Job Pure__* |? PSBeginTime -ge ((Get-Date).AddSeconds(-10))) {
      return
    }

    else {
      Get-Job Pure__* |? State -eq Completed | Remove-Job
      Get-Job Pure__* |? State -eq Stopped   | Remove-Job
    }

    # get the before fetch state
    $currentHead = cat "$($gitStatus.GitDir)/FETCH_HEAD"

    $job = Start-Job -Name "Pure__GitFetch"-ScriptBlock {
      param($gitDir, $currentHead)

      git -C $gitDir fetch;
      $newHead = cat "$gitDir/FETCH_HEAD"
      Write-Verbose "Old: $currentHead `nNew: $newHead"

      $newHead -and ($newHead -ne $currentHead)
    } -ArgumentList $gitStatus.GitDir, $currentHead

    $name = "Pure__PostFetch_$([Guid]::NewGuid())"
    $null = Register-ObjectEvent $job -EventName StateChanged -MessageData $job.Id `
      -SourceIdentifier $name -MaxTriggerCount 1 -Action {
      if ($sender.State -eq 'Completed') {
        $Global:log += 'status received'
        $hasChanged = Receive-Job -Id $event.MessageData -Keep
        if ($hasChanged) {
          $Global:log += 'updating promt'
          [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
        }
      }
    }
  }
}

function global:prompt {
  $isError = !$?

  asyncGitFetch

  $curPath = $ExecutionContext.SessionState.Path.CurrentLocation.Path
  if ($curPath.ToLower().StartsWith($Home.ToLower())) {
    $curPath = "~" + $curPath.SubString($Home.Length)
  }

  $prompt = "`n$($pure.pwdColor | color)$curPath "

  $gitStatus = if ($null -ne (Get-Module posh-git)) {get-gitstatus} else {$null}
  if ($gitStatus) {
    $prompt += "$($pure.branchColor | color)$($gitStatus.branch)"
    if ($gitStatus.HasWorking -or $gitStatus.HasIndex) {
      $prompt += "*"
    }
    $prompt += " "
    if ($gitStatus.BehindBy) {
      $prompt += "$($pure.remoteColor | color)$($pure.downChar)"
    }

    if ($gitStatus.AheadBy) {
      $prompt += "$($pure.remoteColor | color)$($pure.upChar)"
    }
  }

  if ($lastCmd = Get-History -Count 1) {
    $diff = $lastCmd.EndExecutionTime - $lastCmd.StartExecutionTime
    if ($diff.TotalSeconds -gt 2) {
      $prompt += "$($pure.errorColor | color) ($("{0:f2}" -f $diff.TotalSeconds)s)"
    }
  }

  $promptColor = if ($isError) {$pure.errorColor} else {$pure.PromptColor}
  $prompt += "`n$($promptColor | color)$($pure.PromptChar) "
  $prompt
}

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
    $val = if ($Value -match '^\d*m$') {$null} else {$Value}
    $Value = valueOrDefault $val $Value
  }
  $Global:pure.$option = $value
}

function valueOrDefault($value, $default) {
  "$(if ($value) {$value} else {"$([char]27)[$default"})" +
  "*$([char]27)[0m"
}

function init() {
  $psrOptions = Get-PSReadlineOption

  if ($psrOptions) {
    Set-PSReadLineOption -PromptText ("{0} " -f $pure.PromptChar)
    Set-PSReadLineOption -ContinuationPrompt ("{0}{0} " -f $pure.PromptChar)
    Set-PSReadLineOption -Colors @{ ContinuationPrompt = $psrOptions.EmphasisColor }
    Set-PSReadLineOption -ExtraPromptLineCount 2
  }
}

$Global:pure = [ordered]@{
  'PwdColor'    = valueOrDefault $psrOptions.CommentColor "32m"
  'BranchColor' = valueOrDefault $psrOptions.StringColor "36m"
  'RemoteColor' = valueOrDefault $psrOptions.TypeColor "37m"
  'ErrorColor'  = valueOrDefault $psrOptions.ErrorColor "91m"
  'PromptColor' = valueOrDefault $psrOptions.EmphasisColor "96m"
  'PromptChar'  = '❯'
  'UpChar'      = '⇡'
  'DownChar'    = '⇣'
}

init