# pure-pwsh

PowerShell implementation of the [pure prompt](https://github.com/sindresorhus/pure).

Loads git status information asynchronously so that the prompt doesn't block and is able to update the prompt in
response to file system changes without any user interation.

![summary](./examples/summary.svg)

## Dependencies

- Terminal with ANSI colour support
- PowerShell 7.0+
- Git 2.0+ on your path


## Installation

Install from the [gallery](https://www.powershellgallery.com/packages/pure-pwsh) or clone this repository

```shell
Install-Module pure-pwsh
```

and import it in your profile. If you use this with _posh-git_ (e.g. for its excellent Git completion) then you'll
probably want to import _pure-pwsh_ first so that _posh-git_ doesn't sepnd time configuring its own prompt.

```shell
# ~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1

Import-Module pure-pwsh
Import Module posh-git
```


## Options

Set options on the `$pure` global.

| Option                | Description                             | Default value                                      |
| :-------------------- | :-------------------------------------- | :------------------------------------------------- |
| **`PwdColor`**        | Current directory name colour           | <img src="https://placehold.it/18/0000aa?text=+"/> |
| **`BranchColor`**     | Current branch name colour              | <img src="https://placehold.it/18/6c6c6c?text=+"/> |
| **`DirtyColor`**      | Git dirty marker colour                 | <img src="https://placehold.it/18/ffafd7?text=+"/> |
| **`RemoteColor`**     | Remote status colour (up/down arrows)   | <img src="https://placehold.it/18/00aaaa?text=+"/> |
| **`ErrorColor`**      | Error prompt color                      | <img src="https://placehold.it/18/aa0000?text=+"/> |
| **`PromptColor`**     | Colour of the main prompt               | <img src="https://placehold.it/18/aa00aa?text=+"/> |
| **`TimeColor`**       | Colour used for command timings         | <img src="https://placehold.it/18/ffff00?text=+"/> |
| **`UserColor`**       | Colour of user & hostname in SSH        | <img src="https://placehold.it/18/6c6c6c?text=+"/> |
| **`SlowCommandTime`** | Duration at which command is 'slow'     | `00:05`                                            |
| **`FetchInterval`**   | Interval at which to fetch from remotes | `05:00`                                            |
| **`PromptChar`**      | Prompt character                        | `❯`                                                |
| **`UpChar`**          | Up arrow                                | `⇡`                                                |
| **`DownChar`**        | Down arrow                              | `⇣`                                                |
| **`PendingChar`**     | Shown during git status update          | `⋯`                                                |
| **`WindowTitle`**     | Customise the window title              | `{ $PWD.Path.Replace($HOME, '~')}`                 |
| **`BranchFormatter`** | Customize format of git branch name     | `{ $args }`                                        |
| **`PwdFormatter`**    | Customize format of working dir name    | `{ $PWD.Path.Replace($HOME, '~')}`                 |
| **`PrePrompt`**       | Customize the line above the prompt     | `{ param ($user, $cwd, $git, $slow) … }`           |

## Compatibility

_pure-pwsh_ should work anywhere PowerShell 7 does, including Windows, Mac, and Linux. Due to a [longstanding bug
](https://github.com/PowerShell/PSReadLine/issues/1092) in _PSReadLine_, async updates may not be scheduled on Mac and
Linux until you interact with the console in some way.


## Not currently included

- No vi mode indicator
- No git stash indicator
- No git action indicator (rebase, cherry pick, etc.)
- No python virtual env indicator

Consider [raising an issue](https://github.com/nickcox/pure-pwsh/issues/new) if you want any of the above, or use one
of the recipes below.


## Recipes

### Shorten path segments

Abbreviate each segment of the current path except for the leaf node.

![abbreviated-path](./examples/abbreviated-path.svg)

```
$pure.PwdFormatter = {
  (
    ((Split-Path $pwd).Replace($HOME, '~').Split($pwd.Provider.ItemSeparator) |% {$_[0]}) +
    (Split-Path -Leaf $pwd)
  ) -join '/'
}
```


### Truncate branch name

Truncate the branch name to a maximum of 12 characters.

![truncate branch](./examples/truncate-branch.svg)

```sh
$pure.BranchFormatter = {
  param ($n)
  $n.Length -lt 12 ? $n : ($n[0..11] -join '') + '…'
}
```


### Show git stash indicator

![stash indicator](./examples/stash-indicator.svg)

```sh
$pure.PrePrompt = {
  param ($user, $cwd, $git, $slow)
  "`n$user{0}$cwd $git{1}$slow `n" -f($user ? ' ' : ''), ((git stash list) ? ' ≡ ' : '')
}
```


### Show Python virtual env

![stash indicator](./examples/virtual-env.svg)

```sh
$pure.PrePrompt = {
    param ($user, $cwd, $git, $slow)
    "`n$user{1}{0}$cwd $git $slow `n" -f
    ($user ? ' ' : ''),
    (($ve = $env:virtual_env) ? "$($pure._branchcolor)($(Split-Path -Leaf $ve)) " : "" )
}
```

### One line prompt

![stash indicator](./examples/one-line.svg)

```sh
$pure.UserColor = '38;5;242;4'

$pure.PrePrompt = {
  param ($user, $cwd, $git, $slow)
  $seperator = $pure._branchcolor +  " ❯ "
  "`n$user{0}$cwd{1}$git$slow " -f
    ($user ? $seperator : ''),
    ($git ? $seperator : '')
}
```

### Use a different colour for user and hostname parts

![stash indicator](./examples/user-host.svg)

```sh
$pure.UserFormatter = { param ($ssh, $user, $hostname) $ssh ? "$user`e[32m@$hostname" : '' }
```