# nvim

My Neovim config, built on [LazyVim](https://lazyvim.github.io). Works on macOS and Linux.

## Install

```sh
# back up anything already there
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null
mv ~/.local/share/nvim ~/.local/share/nvim.bak 2>/dev/null

git clone https://github.com/hzerrad/nvim.git ~/.config/nvim

# install everything, then pin every plugin to the commit in lazy-lock.json
nvim --headless "+Lazy! restore" +qa
git -C ~/.config/nvim checkout lazy-lock.json
nvim --headless "+Lazy! restore" +qa
nvim
```

The first install pulls some plugins at their latest commit and rewrites
`lazy-lock.json`. The checkout puts the committed lockfile back, so the second
restore lands on the same versions as every other machine. Mason installs the
language servers and formatters on the first real launch (see `:Mason`).

## Requirements

- Neovim >= 0.11.2
- git, a C compiler, `tree-sitter` CLI (treesitter parsers)
- ripgrep, fd (pickers)
- a [Nerd Font](https://www.nerdfonts.com) in the terminal
- lazygit, gh (git extras)
- language toolchains for the enabled extras: node, go, rust/cargo, python3, java

macOS:

```sh
brew install neovim git ripgrep fd tree-sitter-cli lazygit gh node go rust python openjdk
brew install --cask font-jetbrains-mono-nerd-font
```

Arch Linux:

```sh
sudo pacman -S neovim git base-devel ripgrep fd tree-sitter-cli lazygit github-cli nodejs go rust python jdk-openjdk
```

## Layout

- `lazyvim.json` enables the LazyVim extras: languages, DAP, neo-tree, telescope.
- `lua/config/`: options, keymaps, autocmds, and an OSC 52 clipboard for tmux and SSH.
- `lua/plugins/`: colorscheme (kanagawa) and plugin overrides.
- `plugin/after/transparency.lua` keeps backgrounds transparent across colorscheme changes.

## Updating

`:Lazy update` updates plugins and rewrites `lazy-lock.json`. Commit that file so other
machines can `:Lazy restore` to the same versions.
