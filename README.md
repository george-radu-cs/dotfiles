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
| Editor | Neovim with [LazyVim](https://www.lazyvim.org); Obsidian vaults via obsidian.nvim |
| Toolchains | [mise](https://mise.jdx.dev): Java 11/17/21/25, Node.js LTS, Bun, Python, uv, IPython, Go, TypeScript, Zig, Flutter · official [rustup](https://rustup.rs) · Lua · C/C++ (clang, CMake, Ninja) |
| LaTeX | TeX Live (MacTeX on macOS), latexmk, biber, latexindent, chktex; Skim (macOS) or zathura (Linux) with SyncTeX; vimtex + texlab in Neovim |
| Containers | Docker Desktop (macOS), Docker Engine with Compose and Buildx (Linux) |
| CLI | fzf, ripgrep, fd, bat, eza, zoxide, delta, difftastic, lazygit, lazydocker, yazi, gh, btop, dust, duf, fastfetch, OpenTofu |
| Benchmarks | hyperfine (commands), oha, wrk and k6 (HTTP load) |
| Databases & security | pgcli, mycli, trivy |
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

`./bootstrap.sh install` runs seven steps in order. Each step can also be run on
its own, for example `./bootstrap.sh link`, and every step is safe to re-run.
`./bootstrap.sh help <command>` explains any command in detail, and zsh
completes commands and options with Tab.

| Step | macOS | Linux |
| --- | --- | --- |
| `packages` | Homebrew and `packages/Brewfile` (`--extra` adds `Brewfile.extra`) | `packages/{arch,fedora,debian}.txt`, WezTerm repository, mise, desktop apps from Flathub (`packages/flatpak.txt`) |
| `link` | Symlinks every package in `home/` into `$HOME`; existing files are moved to a backup | same |
| `toolchains` | `mise install` (languages), rustup with clippy, rustfmt and rust-analyzer | same, plus the CLI tools from `config.linux.toml` |
| `docker` | Verifies Docker Desktop | Docker repository, engine, `/etc/docker/daemon.json`, service, `docker` group |
| `fonts` | Installed by the Brewfile | JetBrainsMono Nerd Font (pinned release) in `~/.local/share/fonts` |
| `shell` | Login shell, zsh plugins, tmux plugins, Neovim plugins from `lazy-lock.json`, theme | same |
| `kde` | nothing | KDE Plasma settings saved in `kde/` (shortcuts, window manager, keyboard, theme, panels) |

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

For the command-line tools (bat, eza, zoxide, fd, ripgrep, fzf, lazygit, …),
tmux and Neovim keys, and everyday workflows, see [docs/TOOLS.md](docs/TOOLS.md).

## Maintenance

```sh
./bootstrap.sh doctor     # health report; suggests a fix for every problem
./bootstrap.sh update     # upgrade packages, mise tools, Rust, zsh/tmux/Neovim plugins, TeX Live
./bootstrap.sh prune      # list packages and tool versions the repo no longer manages
./bootstrap.sh prune -y   # …and remove them
```

`update` also refreshes Neovim's treesitter parsers and Mason tools. Commit the
resulting `lazy-lock.json` to keep every machine on the same plugin versions.

## KDE Plasma

Plasma settings are copied rather than linked, because Plasma replaces its
config files when it saves them.

```sh
./bootstrap.sh kde-save   # on a configured machine: copy its Plasma settings into kde/
./bootstrap.sh kde        # on another machine: apply them (log out and in afterwards)
```

`theme <name>` also generates a matching Plasma colour scheme and applies it
in a Plasma session.

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
- Languages come from mise on every OS. CLI tools come from Homebrew on macOS
  and from mise on Linux, so all three distributions run the same versions.
- LaTeX builds keep auxiliary files in `.build/`; the PDF stays next to the
  source. Defaults live in `~/.config/latexmk/latexmkrc`, and a project's own
  `.latexmkrc` overrides them (e.g. `$pdf_mode = 4;` for LuaLaTeX).
- MacTeX's `biber` launcher fails with current Xcode versions; on Apple Silicon
  the bootstrap extracts its working binary to `~/.local/bin/biber` and removes
  it again once TeX Live ships a fixed one.
