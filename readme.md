# Note

This beta is intended for use with PSReadLine v2.0-beta4 or later.
You can check your version with something like:

```try { $m = Get-Module psreadline; $m.Version.ToString(); $m.PrivateData.PSData.Prerelease } catch { }```

Update with `Update-Module PSReadline -AllowPrerelease` if necessary.

# pure-pwsh

> PowerShell implementation of the [pure prompt](https://github.com/sindresorhus/pure).

![](screenshot.svg)

## Dependencies

- Terminal with ANSI colour support
  (e.g. any modern version of Windows 10, ConEmu, Hyper, ansicon, etc.)
- PSReadLine for async prompt updates. Works best with PSReadLine 2.0.

## Options

Set options on the `$pure` global.

| Option                | Description                               | Default value                                      |
| :-------------------- | :---------------------------------------- | :------------------------------------------------- |
| **`PwdColor`**        | Colour of the current directory name.     | <img src="https://placehold.it/18/0000aa?text=+"/> |
| **`BranchColor`**     | Colour of the current branch name.        | <img src="https://placehold.it/18/aaaaaa?text=+"/> |
| **`RemoteColor`**     | Colour of remote status (up/down arrows). | <img src="https://placehold.it/18/00aaaa?text=+"/> |
| **`ErrorColor`**      | Colour of error prompt and slow commands. | <img src="https://placehold.it/18/aa0000?text=+"/> |
| **`PromptColor`**     | Colour of the main prompt.                | <img src="https://placehold.it/18/aa00aa?text=+"/> |
| **`PromptChar`**      | Prompt character.                         | `❯` (or `→` on PSReadLine < 2.0)                   |
| **`UpChar`**          | Up arrow.                                 | `⇡` (or `↑` on PSReadLine < 2.0)                   |
| **`DownChar`**        | Down arrow.                               | `⇣` (or `↓` on PSReadLine < 2.0)                   |
| **`SlowCommandTime`** | Duration at which command is 'slow'.      | `00:05`                                            |
| **`FetchInterval`**   | Period at which to fetch from remotes.    | `05:00`                                            |
| **`BranchFormatter`** | Customize format of git branch name.      | `{ $args }`                                        |
| **`PwdFormatter`**    | Customize format of working dir name.     | `{ param ($cwd) $cwd.Replace($HOME, '~') }`        |
| **`PrePrompt`**       | Customize the line above the prompt.      | ``{ param ($cwd, $git, $slow) "`n$cwd $git $slow"`n }``|

To customise the formatting of the current git branch or working directory, provide a function that
transforms a string parameter into a string output. For example, this truncates the branch name by
underscore delimited segments:

```sh
$pure.BranchFormatter = {
     $args |% {
       @(((($_ -split '_' | select -First 3) -join '_') + '…'), $_)
     } | sort Length | select -First 1
}
```

Similarly, you can customise the entire upper line by providing a function that transforms three string parameters
(`$cwd`, `$git` and `$slow`) into a string output. For example, to include your username before the directory info:

```sh
$pure.PrePrompt = {param ($cwd, $git, $slow) "`n$($pure._branchColor)$([Environment]::UserName) $cwd $git $slow`n"}
```

Or to put the entire prompt on one line, remove the `` `n `` at the end of the pre-prompt:

```sh
$pure.PrePrompt = {param ($cwd, $git, $slow) "`n$cwd $git $slow"}
```

Further customisations can be made, for example to colour your username you could combine it with an ANSI escape code:

```sh
myColours = @{ blue = "`e[38;5;31m" } # "$([char]27)[38;5;31m" on PowerShell < 6.0

$pure.PrePrompt =
  {param ($cwd, $git, $slow) "`n$($myColours.blue)$([Environment]::UserName) $cwd $git $slow"}
```
which colours the username [deep sky blue 3](https://jonasjacek.github.io/colors).

## Installation

Install from the [gallery](https://www.powershellgallery.com/packages/pure-pwsh) or clone this repository:

```shell
Install-Module pure-pwsh -AllowPrerelease
```

and import it in your profile. If you use this with `posh-git` (recommended for its excellent command completion)
then you'll probably want to import `pure-pwsh` first so that `posh-git` doesn't waste time configuring the prompt.

```shell
Import-Module pure-pwsh
```

## Compatibility

The packaged dependencies are built for the Windows x64 platform. To build for an alternative platform,
`cd` into the directory containing `PurePwsh.csproj` (i.e. `$env:PSModulePath/pure-pwsh/[version]/pure-pwsh`)
and run:

```shell
dotnet publish -o bin -c Release -r [your-runtime] # https://docs.microsoft.com/en-us/dotnet/core/rid-catalog
```

## Not currently included

- Does not display username and host for remote sessions
- Does not set window title
- No vi mode indicator

Consider [raising an issue](https://github.com/nickcox/pure-pwsh/issues/new) if you want any of the above.
