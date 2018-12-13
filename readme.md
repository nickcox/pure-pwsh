# pure-pwsh

> PowerShell implementation of the [pure prompt](https://github.com/sindresorhus/pure).

![](screenshot.svg)

## Dependencies

- Terminal with ANSI colour support
  (e.g. any modern version of Windows 10, ConEmu, Hyper, ansicon, etc.)
- PSReadLine for async prompt updates and colour scheme integration
  (tested against 2.0, should mostly work on 1.x too)
- posh-git _and_ git executable on `$env:path` for git features

## Options

Set options on the `$pure` global.

| Option                | Description                                       | Default value                                       |
| :-------------------- | :-------------------------------------------------| :-------------------------------------------------- |
| **`PwdColor`**        | Colour of the current directory name.             | <img src="https://placehold.it/16/0000aa?text=+"/>  |
| **`BranchColor`**     | Colour of the current branch name.                | <img src="https://placehold.it/16/aaaaaa?text=+"/>  |
| **`RemoteColor`**     | Colour for remote status (up and down arrows).    | <img src="https://placehold.it/16/00aaaa?text=+"/>  |
| **`ErrorColor`**      | Colour for the error prompt and slow commands.    | <img src="https://placehold.it/16/aa0000?text=+"/>  |
| **`PromptColor`**     | Colour for the main prompt.                       | <img src="https://placehold.it/16/aa00aa?text=+"/>  |
| **`PromptChar`**      | Prompt character.                                 | `❯`                                                 |
| **`UpChar`**          | Up arrow.                                         | `⇡`                                                 |
| **`DownChar`**        | Down arrow.                                       | `⇣`                                                 |
| **`SlowCommandTime`** | Timespan at which command is considered 'slow'.   | `00:05`                                             |
| **`FetchInterval  `** | Period at which to check remotes for updates.     | `05:00`                                             |
| **`BranchFormatter`** | Function to customize format of git branch name.  | `{$args}`                                           |
| **`PwdFormatter`**    | Function to customize format of working dir name. | `{$args -replace [Regex]::Escape($HOME),'~'}`       |

To customize the formatting of the current git branch or working directory, provide a function that
transforms a string parameter into a string output. For example, this truncates the branch name by
underscore delimited segments:

```sh
$pure.BranchFormatter = {
     $args |% {
       @(((($_.Split('_') | select -First 3) -join '_') + '…'), $_)
     } | sort Length | select -First 1
}
  ```

## Installation

Install from the [gallery](https://www.powershellgallery.com/packages/pure-pwsh) or clone this repository:

```shell
Install-Module pure-pwsh
```

and import it in your profile _after_ posh-git:

```shell
Import-Module pure-pwsh
```

## Not currently included

- Does not display username and host for remote sessions
- Does not set window title
- No vi mode indicator
