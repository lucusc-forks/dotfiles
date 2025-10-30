# Dotfiles

Welcome to my world! Here you'll find a collection of configuration files for various tools and programs that I use on a daily basis. These dotfiles have been carefully curated and customized to streamline **my** workflow and improve **my** productivity. Your results may vary, but feel free to give it a try! Whether you're a fellow developer looking to optimize your setup or just curious about how I organize my digital life, I hope you find something useful in these dotfiles. So take a look around and feel free to borrow, modify, or fork to your heart's content. Happy coding!

> **Note**
> Did you arrive here through my YouTube talk, [vim + tmux](https://www.youtube.com/watch?v=5r6yzFEXajQ)? My dotfiles have changed tremendously since then, but feel free to peruse the state of this repo [at the time the video was recorded](https://github.com/nicknisi/dotfiles/tree/aa72bed5c4ecec540a31192581294818b69b93e2).

![capture-20221204193335](https://user-images.githubusercontent.com/293805/205530265-1d0b1a7f-ae2f-4c22-942c-2a1efa0f83a6.png)

## Initial setup

The first thing you need to do is to clone this repo into a location of your choosing. For example, if you have a `~/Developer` directory where you clone all of your git repos, that's a good choice for this one, too. This repo is setup to not rely on the location of the dotfiles, so you can place it anywhere.

> **Note**
> If you're on macOS, you'll also need to install the XCode CLI tools before continuing.

```bash
xcode-select --install
```

```bash
git clone git@github.com:nicknisi/dotfiles.git
```

> **Note**
> This dotfiles configuration is set up in such a way that it _shouldn't_ matter where the repo exists on your system.

The script, `install.sh` is the one-stop for all things setup, backup, and installation.

```bash
> ./install.sh help

Usage: install.sh {backup|link|homebrew|shell|terminfo|macos|all}
```

### `backup`

```bash
./install.sh backup
```

Create a backup of the current dotfiles (if any) into `~/.dotfiles-backup/`. This will scan for the existence of every file that is to be symlinked and will move them over to the backup directory. It will also do the same for vim setups, moving some files in the [XDG base directory](http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html), (`~/.config`).

- `~/.config/nvim/` - The home of [neovim](https://neovim.io/) configuration
- `~/.vim/` - The home of vim configuration
- `~/.vimrc` - The main init file for vim

### `link`

```bash
./install.sh link
```

The `link` command will create [symbolic links](https://en.wikipedia.org/wiki/Symbolic_link) from the dotfiles directory into the `$HOME` directory, allowing for all of the configuration to _act_ as if it were there without being there, making it easier to maintain the dotfiles in isolation.

### `homebrew`

```bash
./install homebrew
```

The `homebrew` command sets up [homebrew](https://brew.sh/) by downloading and running the homebrew installers script. Homebrew is a macOS package manager, but it also work on linux via Linuxbrew. If the script detects that you're installing the dotfiles on linux, it will use that instead. For consistency between operating systems, linuxbrew is set up but you may want to consider an alternate package manager for your particular system.

Once homebrew is installed, it executes the `brew bundle` command which will install the packages listed in the [Brewfile](./Brewfile).

### `shell`

```bash
./install.sh shell
```

The `shell` command sets up the recommended shell configuration for the dotfiles setup. Specifically, it sets the shell to [zsh](https://www.zsh.org/) using the `chsh` command.

### `terminfo`

```bash
./install.sh terminfo
```

This command uses `tic` to set up the terminfo, specifically to allow for _italics_ within the terminal. If you don't care about that, you can ignore this command.

### `macos`

```bash
./install.sh macos
```

The `macos` command sets up macOS-specific configurations using the `defaults write` commands to change default values for macOS.

- Finder: show all filename extensions
- show hidden files by default
- only use UTF-8 in Terminal.app
- expand save dialog by default
- Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
- Enable subpixel font rendering on non-Apple LCDs
- Use current directory as default search scope in Finder
- Show Path bar in Finder
- Show Status bar in Finder
- Disable press-and-hold for keys in favor of key repeat
- Set a blazingly fast keyboard repeat rate
- Set a shorter Delay until key repeat
- Enable tap to click (Trackpad)
- Enable Safari’s debug menu

### `all`

```bash
./install.sh all
```

This command runs all of the installation tasks described above, in full, with the exception of the `backup` script. You must run that one manually.

## ZSH Configuration

The prompt for ZSH is configured in the `zshrc.symlink` file and performs the following operations.

- Sets `EDITOR` to `nvim`
- Loads any `~/.terminfo` setup
- Sets `CODE_DIR` to `~/Developer`. This can be changed to the location you use to put your git checkouts, and enables fast `cd`-ing into it via the `c` command
- Recursively searches the `$DOTFILES/zsh` directory for any `.zsh` files and sources them
- Sources a `~/.localrc`, if available for configuration that is machine-specific and/or should not ever be checked into git
- Adds `~/bin` and `$DOTFILES/bin` to the `PATH`

### Prompt

Aloxaf/fzf-tab
The prompt is meant to be simple while still providing a lot of information to the user, particularly about the status of the git project, if the PWD is a git project. This prompt sets `precmd`, `PROMPT` and `RPROMPT`. The `precmd` shows the current working directory in it and the `RPROMPT` shows the git and suspended jobs info. The main symbol used on the actual prompt line is `❯`.

The prompt attempts to speed up certain information lookups by allowing for the prompt itself to be asynchronously rewritten as data comes in. This prevents the prompt from feeling sluggish when, for example, the user is in a large git repo and the git prompt commands take a considerable amount of time.

It does this by writing the actual text that will be displayed int he prompt to a temp file, which is then used to update the prompt information when a signal is trapped.

#### Git Prompt

The git info shown on the `RPROMPT` displays the current branch name, along with the following symbols.

- `+` - New files were added
- `!` - Existing files were modified
- `?` - Untracked files exist that are not ignored
- `»` - Current changes include file renaming
- `✘` - An existing tracked file has been deleted
- `$` - There are currently stashed files
- `=` - There are unmerged files
- `⇡` - Branch is ahead of the remote (indicating a push is needed)
- `⇣` - Branch is behind the remote (indicating a pull is needed)
- `⇕` - The branches have diverged (indicating history has changed and maybe a force-push is needed)
- `✔` - The current working directory is clean

#### Jobs Prompt

The prompt will also display a `✱` character in the `RPROMPT` indicating that there is a suspended job that exists in the background. This is helpful in keeping track of putting vim in the background by pressing CTRL-Z.

#### Node Prompt

If a `package.json` file or a `node_modules` directory exists in the current working directory, display the node symbol, along with the current version of Node. This is useful information when switching between projects that depend on different versions of Node.

## Neovim setup

> **Note**
> This is no longer a vim setup. The configuration has been moved to be Neovim-specific and (mostly) written in [Lua](https://www.lua.org/). `vim` is also set up as an alias to `nvim` to help with muscle memory.

The simplest way to install Neovim is to install it from homebrew.

```bash
brew install neovim
```

However, it was likely installed already if you ran the `./install.sh brew` command provided in the dotfiles.

All of the configuration for Neovim starts at `config/nvim/init.lua`, which is symlinked into the `~/.config/nvim` directory.

> **Warning**
> The first time you run `nvim` with this configuration, it will likely have a lot of errors. This is because it is dependent on a number of plugins being installed.

### Installing plugins

On the first run, all required plugins should automaticaly by installed by
[lazy.nvim](https://github.com/folke/lazy.nvim), a plugin manager for neovim.

All plugins are listed in [plugins.lua](./config/nvim/lua/plugins.lua). When a plugin is added, it will automatically be installed by lazy.nvim. To interface with lazy.nvim, simply run `:Lazy` from within vim.

> **Note**
> Plugins can be synced in a headless way from the command line using the `vimu` alias.


## Docker Setup

A Dockerfile exists in the repository as a testing ground for linux support. To set up the image, make sure you have Docker installed and then run the following command.

```bash
docker build -t dotfiles --force-rm --build-arg PRIVATE_KEY="$(cat ~/.ssh/id_rsa)" --build-arg PUBLIC_KEY="$(cat ~/.ssh/id_rsa.pub)" .
```

This should create a `dotfiles` image which will set up the base environment with the dotfiles repo cloned. To run, execute the following command.

```bash
docker run -it --rm dotfiles
```

This will open a bash shell in the container which can then be used to manually test the dotfiles installation process with linux.

## Preferred software

I almost exclusively work on macOS, so this list will be specific to that operating system, but several of these
reccomendations are also available, cross-platform.

- [Kitty](https://sw.kovidgoyal.net/kitty/) - A GPU-based terminal emulator

## Questions

If you have questions, notice issues, or would like to see improvements, please open a new [discussion](https://github.com/nicknisi/dotfiles/discussions/new) and I'm happy to help you out!

## Plugin Management

This configuration uses [Zinit](https://github.com/zdharma-continuum/zinit) as the Zsh plugin manager for fast, asynchronous plugin loading. Zinit offers several advantages:

- Significantly faster shell startup time through deferred/turbo loading
- Asynchronous plugin loading that doesn't block shell initialization
- Fine-grained control over when and how plugins are loaded
- Simple plugin updates with `zinit update`

During installation, the setup script will automatically install Zinit if it's not already present. You can also manually install it by running:

```bash
zsh /Users/Shared/dev/personal/dotfiles/zsh/zinit-installer.zsh
```

### Managing Plugins

To update all plugins:

```bash
zinit update --all
```

To see which plugins are loaded (active plugins):

```bash
zinit zstatus
```

To see the actual plugin directories (manually check what's installed):

```bash
ls -la ~/.local/share/zinit/plugins
```

To see plugin load times and performance metrics:

```bash
zinit times
```

To get detailed information about a specific plugin:

```bash
zinit report plugin-name
# Example: zinit report zsh-users/zsh-autosuggestions
```
