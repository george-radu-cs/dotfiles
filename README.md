# dotfiles

Personal development environment for macOS and Linux (Arch, Fedora,
Debian/Ubuntu with KDE Plasma), managed with
[GNU Stow](https://www.gnu.org/software/stow/) and a single idempotent
bootstrap script.

Configuration files are symlinked from this repository into `$HOME`, so changes
made in `~/.config/<app>` are changes to the repository and can be committed
directly.

## Contents

| Area | Tools |
| --- | --- |
| Shell | zsh, [antidote](https://github.com/mattmc3/antidote) (selected oh-my-zsh plugins), [Starship](https://starship.rs) |
| Terminal | [WezTerm](https://wezterm.org), tmux, JetBrainsMono Nerd Font |
| Editor | Neovim with [LazyVim](https://www.lazyvim.org) |
| Toolchains | [mise](https://mise.jdx.dev): Java 11/17/21/25, Node.js LTS, Bun, Python, uv, IPython, Zig, OpenTofu · official [rustup](https://rustup.rs) · Go, TypeScript, Lua · C/C++ (clang, CMake, Ninja) |
| LaTeX | TeX Live (MacTeX on macOS), latexmk, biber, latexindent, chktex; Skim (macOS) or zathura (Linux) with SyncTeX; vimtex + texlab in Neovim |
| Containers | Docker Desktop (macOS), Docker Engine with Compose and Buildx (Linux) |
| CLI | fzf, ripgrep, fd, bat, eza, zoxide, delta, lazygit, yazi, gh, btop, fastfetch |
| Theme | Gruvbox dark (hard) by default; Gruvbox light (hard); Kanagawa wave, dragon and lotus |

## Requirements

- macOS (Apple Silicon or Intel), Arch Linux, Fedora, or Debian 12+ /
  Ubuntu 22.04+
- `git` and `curl`
- An administrator account (`sudo`) for system packages
- macOS: signed in to the App Store, for apps installed through `mas`

## Installation

```sh
git clone https://github.com/george-radu-cs/dotfiles.git ~/Personal/dotfiles
cd ~/Personal/dotfiles

./bootstrap.sh                # show the available commands
./bootstrap.sh install -n     # preview every action without changing anything
./bootstrap.sh backup         # optional: snapshot the current configuration
./bootstrap.sh install        # install and configure everything
```

Open a new terminal (or run `exec zsh`) when it finishes. On Linux, log out
and back in once so that membership of the `docker` group takes effect.

On a fresh Mac, the first `git` command prompts to install the Xcode Command
Line Tools. Accept, then run the clone again.

### What the bootstrap does

`./bootstrap.sh install` runs six steps in order. Each step can also be run on
its own, for example `./bootstrap.sh link`, and every step is safe to re-run.
`./bootstrap.sh help <command>` explains any command in detail, and zsh
completes commands and options with Tab.

| Step | macOS | Linux |
| --- | --- | --- |
| `packages` | Homebrew and `packages/Brewfile` (`--extra` adds `Brewfile.extra`) | `packages/{arch,fedora,debian}.txt`, WezTerm repository, mise |
| `link` | Symlinks every package in `home/` into `$HOME`; existing files are moved to a backup | same |
| `toolchains` | `mise install`, rustup with clippy, rustfmt and rust-analyzer | same, plus Go, TypeScript and CLI tools from `config.linux.toml` |
| `docker` | Verifies Docker Desktop | Docker repository, engine, `/etc/docker/daemon.json`, service, `docker` group |
| `fonts` | Installed by the Brewfile | JetBrainsMono Nerd Font (pinned release) in `~/.local/share/fonts` |
| `shell` | Login shell, zsh plugins, tmux plugins, Neovim plugins from `lazy-lock.json`, theme | same |

Installed packages are not upgraded by the bootstrap. Upgrade deliberately
with the commands listed under [Maintenance](#maintenance).

## Usage

| Command | Description |
| --- | --- |
| `dots` | Open lazygit in this repository to review, commit and push changes |
| `dots <git args>` | Run git in this repository, e.g. `dots status`, `dots pull` |
| `theme` | List themes; `theme <name>` switches WezTerm, tmux, Neovim, bat, delta, fzf and btop |
| `java11` … `java25` | Switch the JDK for the current shell |
| `mise use <tool>@<version>` | Pin a tool version for the current project |
| `zbench` | Measure shell startup time |

## Maintenance

```sh
brew upgrade            # macOS packages
mise upgrade            # language toolchains and Linux CLI tools
rustup update           # Rust
antidote update         # zsh plugins
```

Neovim plugins are updated from inside Neovim with `:Lazy update`; commit the
resulting `lazy-lock.json` to keep every machine on the same versions.

## Backup and restore

Nothing is deleted by the bootstrap. Files it replaces are moved to
`~/.dotfiles-backup/<date>/` together with a manifest that records every
change.

```sh
./bootstrap.sh backup               # copy the current configuration and shell history
./bootstrap.sh clean                # move leftovers of a previous setup into a backup
./bootstrap.sh backups              # list restorable backups
./bootstrap.sh restore [name]       # undo the newest (or the named) backup
./bootstrap.sh check                # report missing or broken links
./bootstrap.sh unlink               # remove all links created by this repository
```

## Repository layout

```text
bootstrap.sh            entry point
lib/                    bootstrap steps (packages, link, toolchains, docker, fonts, shell)
packages/               Brewfile, Brewfile.extra and the Arch, Fedora and Debian package lists
home/<package>/         stow packages; each mirrors the layout of $HOME
themes/                 colour palettes used by the theme command
system/docker/          daemon.json installed to /etc/docker on Linux
```

## Customization

Machine-specific settings belong in untracked files that the configuration
loads when present:

| File | Purpose |
| --- | --- |
| `~/.config/zsh/local.zsh` | Aliases, environment variables and secrets for one machine |
| `~/.config/git/config.local` | Work identities (`includeIf`), signing keys; see `config.local.example` |

To add a configuration, create `home/<name>/` mirroring its location under
`$HOME`, add the name to `LINK_PACKAGES` in `lib/link.sh`, and run
`./bootstrap.sh link`. To add a theme, copy a palette in `themes/`.

## Notes

- Rust is installed with the official rustup installer rather than a package
  manager.
- All JDKs are Eclipse Temurin (Adoptium) builds of OpenJDK: 11, 17, 21 and 25.
- On Linux, CLI tools come from mise so that every distribution runs the same
  versions.
- LaTeX builds keep auxiliary files in `.build/`; the PDF stays next to the
  source. Defaults live in `~/.config/latexmk/latexmkrc`, and a project's own
  `.latexmkrc` overrides them (e.g. `$pdf_mode = 4;` for LuaLaTeX).
- MacTeX's `biber` launcher fails with current Xcode versions; on Apple Silicon
  the bootstrap extracts its working binary to `~/.local/bin/biber` and removes
  it again once TeX Live ships a fixed one.
