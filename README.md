# dotfiles

Personal development environment for macOS and Linux (Arch, Fedora,
Debian/Ubuntu with KDE Plasma), managed with
[GNU Stow](https://www.gnu.org/software/stow/) and a single idempotent
bootstrap script.

Configuration files are symlinked from this repository into `$HOME`, so changes
made in `~/.config/<app>` are changes to the repository and can be committed
directly.

## Contents

| Area                 | Tools                                                                                                                                                                                          |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Shell                | zsh, [antidote](https://github.com/mattmc3/antidote) (selected oh-my-zsh plugins), [Starship](https://starship.rs)                                                                             |
| Terminal             | [WezTerm](https://wezterm.org), tmux, JetBrainsMono Nerd Font                                                                                                                                  |
| Editor               | Neovim with [LazyVim](https://www.lazyvim.org); Obsidian vaults via obsidian.nvim · VS Code with the same Neovim inside (vscode-neovim)                                                        |
| Toolchains           | [mise](https://mise.jdx.dev): Java 11/17/21/25, Node.js LTS, Bun, Python, uv, IPython, Go, TypeScript, Zig, Flutter · official [rustup](https://rustup.rs) · Lua · C/C++ (clang, CMake, Ninja) |
| LaTeX                | TeX Live (MacTeX on macOS), latexmk, biber, latexindent, chktex; Skim (macOS) or zathura (Linux) with SyncTeX; vimtex + texlab in Neovim                                                       |
| Containers           | Docker Desktop (macOS), Docker Engine with Compose and Buildx (Linux)                                                                                                                          |
| Desktop apps         | WezTerm, Docker Desktop, Alfred, Obsidian, Skim, Bitwarden (App Store) on macOS; WezTerm on Linux                                                                                              |
| CLI                  | fzf, ripgrep, fd, bat, eza, zoxide, delta, difftastic, lazygit, lazydocker, yazi, gh, btop, dust, duf, fastfetch, OpenTofu                                                                     |
| Kubernetes           | kubectl, kind, k9s, kubectx/kubens, Helm                                                                                                                                                       |
| Benchmarks           | hyperfine (commands), oha, wrk and k6 (HTTP load)                                                                                                                                              |
| Databases & security | pgcli, mycli, trivy                                                                                                                                                                            |
| Theme                | Gruvbox dark (hard) by default; Gruvbox light (hard); Kanagawa wave, dragon and lotus                                                                                                          |

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

Open a new terminal (or run `exec zsh`) when it finishes. From then on the
bootstrap also runs from any directory as `dotctl` (for example `dotctl
doctor`); `./bootstrap.sh` inside the repo keeps working. On Linux, log out
and back in once so that membership of the `docker` group takes effect.

On a fresh Mac, the first `git` command prompts to install the Xcode Command
Line Tools. Accept, then run the clone again.

### What the bootstrap does

`dotctl install` runs seven steps in order. Each step can also be run on
its own, for example `dotctl link`, and every step is safe to re-run.
`dotctl help <command>` explains any command in detail, and zsh
completes commands and options with Tab.

| Step         | macOS                                                                                                                                                | Linux                                                                                                                                                          |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `packages`   | Homebrew and `packages/Brewfile`, including App Store apps via `mas` (`--extra` adds `Brewfile.extra`)                                               | `packages/{arch,fedora,debian}.txt`, WezTerm repository, mise; wrk is built from source on Arch and Fedora                                                     |
| `link`       | Symlinks every package in `home/` into `$HOME`, and VS Code's settings and keybindings; existing files are moved to a backup                         | same                                                                                                                                                           |
| `toolchains` | `mise install` (languages), rustup with clippy, rustfmt and rust-analyzer; LaTeX: latexindent's Perl modules, Skim linked to Neovim, a working biber | same, plus the CLI tools from `config.linux.toml` (no Skim or biber step)                                                                                      |
| `docker`     | Verifies Docker Desktop                                                                                                                              | Docker repository, engine, `/etc/docker/daemon.json`, service, `docker` group                                                                                  |
| `fonts`      | Installed by the Brewfile                                                                                                                            | JetBrainsMono Nerd Font (pinned release) in `~/.local/share/fonts`                                                                                             |
| `shell`      | Login shell, zsh plugins, tmux plugins, tldr pages, Neovim plugins from `lazy-lock.json`, VS Code extensions, theme                                  | same                                                                                                                                                           |
| `kde`        | nothing                                                                                                                                              | KDE Plasma settings saved in `kde/` (shortcuts, window manager, keyboard, theme, panels)                                                                       |

Installed packages are not upgraded by the bootstrap. Upgrade deliberately
with the commands listed under [Maintenance](#maintenance).

## Usage

| Command                     | Description                                                                                                 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `dots`                      | Open lazygit in this repository to review, commit and push changes                                          |
| `dots <git args>`           | Run git in this repository, e.g. `dots status`, `dots pull`                                                 |
| `theme`                     | List themes; `theme <name>` switches WezTerm, tmux, Neovim, bat, delta, fzf, btop and the KDE colour scheme |
| `java11` … `java25`         | Switch the JDK for the current shell                                                                        |
| `mise use <tool>@<version>` | Pin a tool version for the current project                                                                  |
| `zbench`                    | Measure shell startup time                                                                                  |

For the command-line tools (bat, eza, zoxide, fd, ripgrep, fzf, lazygit, …),
tmux and Neovim keys, and everyday workflows, see [docs/TOOLS.md](docs/TOOLS.md).

## Maintenance

```sh
dotctl doctor     # health report; suggests a fix for every problem
dotctl update     # pick what to upgrade (enter alone: everything): packages, mise tools, Rust, tldr pages, zsh/tmux/Neovim plugins, TeX Live
dotctl update nvim zsh   # only those steps; -y updates everything without asking
dotctl prune      # list packages you installed that the repo doesn't manage, and unused mise versions
dotctl prune -y   # …and remove them
```

`update` also refreshes Neovim's treesitter parsers and Mason tools. Commit the
resulting `lazy-lock.json` to keep every machine on the same plugin versions.
`prune` never touches App Store apps, taps, or libraries other packages need.

## KDE Plasma

Plasma settings are copied rather than linked, because Plasma replaces its
config files when it saves them.

```sh
dotctl kde-save   # on a configured machine: copy its Plasma settings into kde/
dotctl kde        # on another machine: apply them (log out and in afterwards)
```

`theme <name>` also generates a matching Plasma colour scheme and applies it
in a Plasma session.

## Backup and restore

Nothing is deleted by the bootstrap. Files it replaces are moved to
`~/.dotfiles-backup/<date>/` together with a manifest that records every
change.

```sh
dotctl backup               # copy the current configuration and shell history
dotctl clean                # move leftovers of a previous setup into a backup
dotctl backups              # list restorable backups
dotctl restore [name]       # undo the newest (or the named) backup
dotctl check                # report missing or broken links
dotctl unlink               # remove all links created by this repository
```

## Repository layout

```text
bootstrap.sh            entry point: commands, help, step order
lib/                    common (helpers) · packages · link (stow, backups, restore)
                        toolchains · latex · docker · fonts · shell · kde · maintenance
packages/               Brewfile, Brewfile.extra, arch/fedora/debian lists
home/<package>/         stow packages; each mirrors the layout of $HOME
themes/                 colour palettes used by the theme command
system/docker/          daemon.json installed to /etc/docker on Linux
kde/                    Plasma settings saved by `kde-save` (created on first save)
vscode/                 VS Code settings.json, keybindings.json (linked) and extensions.txt
docs/TOOLS.md           guide to the command-line tools, keys and workflows
```

## Customization

Machine-specific settings belong in untracked files that the configuration
loads when present:

| File                         | Purpose                                                                 |
| ---------------------------- | ----------------------------------------------------------------------- |
| `~/.config/zsh/local.zsh`    | Aliases, environment variables and secrets for one machine              |
| `~/.config/git/config.local` | Work identities (`includeIf`), signing keys; see `config.local.example` |

VS Code settings and keybindings live in `vscode/` rather than in VS Code's own
Settings Sync: changing a setting in VS Code edits the repo, and
`vscode/extensions.txt` is the extension list.

To add a configuration, create `home/<name>/` mirroring its location under
`$HOME`, add the name to `LINK_PACKAGES` in `lib/link.sh`, and run
`dotctl link`. To add a theme, copy a palette in `themes/`.
