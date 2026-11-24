# Tools guide

What this setup gives you on the command line, what each tool replaces, the
commands worth knowing, and workflows that combine them. Everything here is
installed by `./bootstrap.sh install`.

## At a glance

| Instead of | Use | Why |
| --- | --- | --- |
| `cat` | `bat` | syntax highlighting, line numbers, git changes in the margin |
| `ls` | `ls` (now `eza`) | colours, icons, git status, tree view |
| `cd` | `z` (zoxide) | jumps to folders you use often by a fragment of their name |
| `find` | `fd` | simpler syntax, fast, skips `.gitignore`d files |
| `grep -r` | `rg` (ripgrep) | much faster, respects `.gitignore`, readable output |
| `git diff` output | `delta` | side-by-side-ready, highlighted diffs (automatic in git) |
| git on the command line | `lg` (lazygit) | stage, commit, rebase, push from a terminal UI |
| `top` / `htop` | `btop` | CPU, memory, disks, network and processes in one view |
| `man` | `tldr` | the five examples you actually need |
| file manager | `y` (yazi) | fast terminal file manager with previews |
| `neofetch` | `fastfetch` | system info, shown when a terminal opens |
| GitHub website | `gh` | pull requests, issues and repos from the terminal |
| JSON in the terminal | `jq` | filter and pretty-print JSON |
| `du` / `df` | `dust` / `duf` | what fills the disk, as a tree / disks at a glance |
| `docker ps`, `docker logs` | `lazydocker` | containers, logs and Compose stacks in one terminal UI |
| `time cmd` | `hyperfine` | repeated runs with mean ± deviation, compare commands |

`cat`, `find` and `grep` still work as before; only `ls` and `vim` are aliased
(to `eza` and `nvim`).

## Moving around

```sh
z dotfiles        # jump to ~/Personal/dotfiles from anywhere (learns as you cd)
z dot conf        # several fragments narrow it down
zi                # pick from your frequent folders with fzf
y                 # yazi file manager; quitting leaves you in the folder you were in
mkcd new-project  # create a folder and enter it
```

zoxide only knows folders you've visited, so use `cd` normally for a few days
and `z` gets better on its own.

## Listing and reading files

```sh
ls / ll / la      # eza: short / long with git status / including hidden files
lt                # tree, two levels deep
bat file.py       # highlighted, paged; bat -p for plain output, bat -A shows whitespace
bat -l json < x   # force a language when reading from a pipe
```

## Finding things

```sh
fd config         # files whose name contains "config"
fd -e md          # all Markdown files;  fd -H …  includes hidden files
rg "TODO"         # search file contents, respects .gitignore
rg -i login -t py # case-insensitive, Python files only;  rg -l … lists file names only
```

fzf key bindings, everywhere in the shell:

| Keys | Does |
| --- | --- |
| `Ctrl-R` | fuzzy-search your command history |
| `Ctrl-T` | insert a file path (with a bat preview) |
| `Alt-C` | cd into a folder (with a tree preview) |
| `Tab` | completion menu with fuzzy search (fzf-tab) |
| `**<Tab>` | fuzzy path completion, e.g. `nvim **<Tab>` |

## Git and GitHub

```sh
lg                # lazygit in the current repo (?, then read the key list)
dots              # lazygit in this dotfiles repo, from anywhere
git diff / show   # delta draws these automatically; n / N jump between files
git dft           # same diff, by difftastic: compares code structure, ignores reformatting
git dshow HEAD    # last commit, structurally;  git dlog -3 for the last three
gh pr list        # open pull requests;  gh pr checkout 12;  gh pr create
gh repo view -w   # open the current repo in the browser
```

## Containers and disk

```sh
lazydocker        # containers, images, volumes, logs; Enter to inspect, ? for keys
dc up -d          # docker compose (alias dc)
dust              # what's using space under the current folder, biggest first
dust -d 2 ~       # two levels deep from your home folder
duf               # all disks: size, used, free
```

## Benchmarking

Commands, with hyperfine:

```sh
hyperfine 'zsh -i -c exit'                       # shell startup, many runs
hyperfine 'rg TODO' 'grep -r TODO .'             # compare two ways of doing something
hyperfine --warmup 1 'go build ./...'            # build time with a warm-up run
hyperfine -p 'make clean' 'make -j8'             # prepare step before every run
hyperfine --export-markdown bench.md '…'         # a results table for a README or PR
```

HTTP services, with oha, wrk and k6:

```sh
oha -z 30s -c 50 http://localhost:8080          # 30 s, 50 connections, live view and histogram
oha -n 1000 -m POST -d '{"a":1}' -H 'Content-Type: application/json' http://localhost:8080/api
wrk -t4 -c200 -d30s http://localhost:8080       # maximum load: 4 threads, 200 connections, 30 s
wrk -t4 -c200 -d30s -s post.lua http://…         # custom requests from a Lua script
k6 run script.js                                # scripted scenario (see below)
```

A minimal k6 test (`script.js`): 20 virtual users for 30 seconds, failing if
the 95th-percentile response time goes above 300 ms:

```js
import http from "k6/http";
import { check } from "k6";

export const options = {
  vus: 20,
  duration: "30s",
  thresholds: { http_req_duration: ["p(95)<300"] },
};

export default function () {
  const res = http.get("http://localhost:8080/");
  check(res, { "status is 200": (r) => r.status === 200 });
}
```

Which one when: **oha** for a quick check while developing, **wrk** to find the
maximum throughput, **k6** for repeatable tests with several steps and
pass/fail limits (it can run in CI).

## Everyday workflows

### Open a project and start working

```sh
z myproject && nvim .          # jump, then <Space>ff to find files
```

### Find where something is used and edit it

```sh
rg -l "fetchUser" | fzf --preview 'bat --color=always {}' | xargs nvim
```

Inside Neovim the same is `<Space>sg` (grep the project) or `<Space>ff` (files).

### Review and commit your work

```sh
lg        # space stages a file, c commits, P pushes, ? shows all keys
```

### Inspect a JSON API response

```sh
curl -s https://api.github.com/repos/neovim/neovim | jq '{stars: .stargazers_count, lang: .language}'
```

### Clean up disk space

```sh
dust ~                   # which folders take the most space
fd -t f -S +500M ~       # files bigger than 500 MB in your home folder
duf                      # free space per disk
```

### Look up how to use a command

```sh
tldr tar                 # the common invocations, without reading the man page
```

## tmux

Prefix is `Ctrl-Space`.

| Keys | Does |
| --- | --- |
| prefix `v` / `b` | split side by side / top and bottom (in the current folder) |
| prefix `c` | new window |
| `Ctrl-h/j/k/l` | move between tmux panes and Neovim splits |
| `Alt-←/→/↑/↓` | move between panes |
| `Shift-←/→`, `Alt-H/L` | previous / next window |
| prefix `Ctrl-k` | clear the screen and scrollback |
| prefix `r` | reload the tmux config |
| prefix `[` | scroll / copy mode: `v` select, `y` copy, `q` quit |

Windows are named after the folder (at the shell) or the running program.

## Neovim (LazyVim)

`<Space>` is the leader key; press it and wait to see every option.

| Keys | Does |
| --- | --- |
| `<Space>ff` / `<Space><Space>` | find files (hidden files included) |
| `<Space>sg` | search text in the project |
| `<Space>e` | file explorer |
| `<Space>gg` | lazygit inside Neovim |
| `gd` / `gr` / `K` | go to definition / references / documentation |
| `<Space>ca` / `<Space>cr` | code actions / rename |
| `<Space>cf` | format the file |
| `<Space>uC` | try a different colour scheme |
| `<Space>aa` | AI chat (local Ollama model) |
| `\ll` / `\lv` | LaTeX: compile continuously / jump to the PDF |

`:Lazy` manages plugins, `:Mason` language servers and formatters,
`:checkhealth` diagnoses problems.

## Toolchains

```sh
java17 / java21 / java25        # switch the JDK in this shell
mise use node@22                # pin a version for the current project (writes mise.toml)
mise ls                         # what is installed and active
ipython                         # interactive Python
```

## Looking after the setup

```sh
./bootstrap.sh doctor           # health report with fixes
./bootstrap.sh update           # upgrade everything
theme kanagawa-wave             # switch the colour theme everywhere (theme alone lists them)
zbench                          # how fast the shell starts
```

## Worth adding next

More candidates are collected in [IDEAS.md](../IDEAS.md).
