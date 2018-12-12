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
            'DownChar',
            'SlowCommandTime',
            'FetchInterval',
            'BranchFormatter',
            'PwdFormatter')]
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

    $id = {$input}

    $Global:pure = New-Object PSObject -Property (
        [ordered]@{
            PwdColor        = ansiSequence ("34m")
            BranchColor     = ansiSequence ("90m")
            RemoteColor     = ansiSequence ("36m")
            ErrorColor      = ansiSequence ("91m")
            PromptColor     = ansiSequence ("35m")
            PromptChar      = '❯'
            UpChar          = '⇡'
            DownChar        = '⇣'
            SlowCommandTime = [timespan]::FromSeconds(5.0)
            FetchInterval   = [timespan]::FromSeconds(300)
            BranchFormatter = $id
            PwdFormatter    = $id
            DebounceMs      = 500
        })
}