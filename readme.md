# pure-pwsh

> PowerShell implementation of the [pure prompt](https://github.com/sindresorhus/pure).

<img src="screenshot.png" width="840">

## Dependencies

- Terminal with ANSI colour support
  (e.g. any modern version of Windows 10, ConEmu, Hyper, ansicon, etc.)
- PSReadLine for async prompt updates and colour scheme integration
  (tested against 2.0, should mostly work on 1.x too)
- posh-git _and_ git executable on `$env:path` for git features

## Options

Set options on the `$pure` global.

| Option                | Description                                                 | Default value                                              |
| :-------------------- | :---------------------------------------------------------- | :--------------------------------------------------------- |
| **`PwdColor`**        | Colour of the current directory name.                       | <img src="https://placehold.it/16/00aa00/000000?text=+" /> |
| **`BranchColor`**     | Colour of the current branch.                               | <img src="https://placehold.it/16/00aaaa/000000?text=+" /> |
| **`RemoteColor`**     | Colour used for remote status (up and down arrows).         | <img src="https://placehold.it/16/555555/000000?text=+" /> |
| **`ErrorColor`**      | Colour used for the error prompt and long running commands. | <img src="https://placehold.it/16/ff5555/000000?text=+" /> |
| **`PromptColor`**     | Colour used for the main prompt.                            | <img src="https://placehold.it/16/55ffff/000000?text=+" /> |
| **`PromptChar`**      | Prompt character.                                           | `❯`                                                        |
| **`UpChar`**          | Up arrow.                                                   | `⇡`                                                        |
| **`DownChar`**        | Down arrow.                                                 | `⇣`                                                        |
| **`SlowCommandTime`** | Timespan beyond which a command is considered 'slow'.       | `00:00:05`                                                 |
| **`FetchInterval`**   | Interval to check remote for updates. (0 to disable.)       | `00:05:00`                                                 |
| **`Debounce`**        | Ignore successive updates within the given window.          | `00:00:00.5`                                               |

## Installation

Install from the [gallery](https://www.powershellgallery.com/packages/pure-pwsh) or clone this repository:

```shell
Install-Module pure-pwsh
```

and import it in your profile _after_ posh-git:

```shell
Import-Module pure-pwsh
```

# Not currently included

- Does not display username and host for remote sessions
- Does not set window title
- No vi mode indicator
