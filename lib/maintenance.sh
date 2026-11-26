# shellcheck shell=bash
# shellcheck disable=SC2154  # colour variables come from lib/common.sh
# shellcheck disable=SC2015  # `check && ok || err`: the ok/warn helpers always succeed
# Keeping an installed machine healthy:
#   doctor   read-only health report (links, packages, toolchains, Neovim, LaTeX…)
#   update   upgrade what the repo manages; pick the steps or run them all
#   prune    list (and with -y remove) what is installed but no longer managed

_DOC_OK=0 _DOC_WARN=0 _DOC_ERR=0
_doc_ok()   { ok "$*";   _DOC_OK=$((_DOC_OK + 1)); }
_doc_warn() { warn "$*"; _DOC_WARN=$((_DOC_WARN + 1)); }
_doc_err()  { printf '  %s✗%s %s\n' "$_c_red" "$_c_reset" "$*"; _DOC_ERR=$((_DOC_ERR + 1)); }
_doc_head() { printf '\n%s%s%s\n' "$_c_bold" "$*" "$_c_reset"; }

_mise_bin() { command -v mise || echo "$HOME/.local/bin/mise"; }

# On Linux, mise also manages the CLI tools in config.linux.toml.
_mise_env() { if is_linux; then export MISE_ENV=linux; fi; }

# --- doctor --------------------------------------------------------------------

doctor() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  _mise_env

  _doc_head "Links"
  local missing
  missing=$(check_links 2>&1 | grep -c "not linked" || true)
  if (( missing == 0 )); then _doc_ok "all ${#LINK_PACKAGES[@]} packages linked"
  else _doc_err "$missing files not linked — run: $DOTFILES_CMD link"; fi

  _doc_head "Shell"
  if [[ $(basename "${SHELL:-}") == zsh ]]; then _doc_ok "login shell is zsh"; else _doc_warn "login shell is ${SHELL:-unknown}, not zsh"; fi
  local ms
  # Timed by zsh itself: /usr/bin/time isn't installed everywhere (e.g. Debian).
  ms=$(zsh -c 'zmodload zsh/datetime; t=$EPOCHREALTIME; zsh -i -c exit >/dev/null 2>&1; printf "%.0f" $(( (EPOCHREALTIME - t) * 1000 ))' 2>/dev/null || true)
  if (( ${ms:-9999} < 300 )); then _doc_ok "zsh starts in ${ms} ms"; else _doc_warn "zsh starts in ${ms:-?} ms (profile with: ZPROF=1 zsh -i -c exit)"; fi

  _doc_head "Packages"
  if is_macos; then
    local brew_missing
    brew_missing=$(brew bundle check --no-upgrade --verbose --file "$DOTFILES/packages/Brewfile" 2>&1 | grep -c '^→' || true)
    if (( brew_missing == 0 )); then _doc_ok "Brewfile satisfied"
    else _doc_warn "$brew_missing Brewfile entries missing — run: $DOTFILES_CMD packages"; fi
    local outdated
    outdated=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
    (( outdated == 0 )) && _doc_ok "Homebrew packages up to date" || _doc_warn "$outdated Homebrew packages outdated — run: $DOTFILES_CMD update"
  else
    local list="$DOTFILES/packages/$DOTFILES_OS.txt" pkg absent=()
    while IFS= read -r pkg; do
      case $DOTFILES_OS in
        arch)   pacman -Q "$pkg" >/dev/null 2>&1 || absent+=("$pkg") ;;
        fedora) rpm -q "$pkg" >/dev/null 2>&1 || absent+=("$pkg") ;;
        debian) dpkg -s "$pkg" >/dev/null 2>&1 || absent+=("$pkg") ;;
      esac
    done < <(read_list "$list")
    if [[ ${#absent[@]} -eq 0 ]]; then _doc_ok "all packages from $(basename "$list") installed"
    else _doc_warn "${#absent[@]} packages missing: ${absent[*]}"; fi
  fi

  _doc_head "Toolchains"
  local mise
  mise=$(_mise_bin)
  if [[ -x $mise ]]; then
    local m_missing m_outdated
    m_missing=$("$mise" ls 2>/dev/null | grep -c '(missing)' || true)
    m_outdated=$("$mise" outdated 2>/dev/null | tail -n +2 | grep -c . || true)
    (( m_missing == 0 )) && _doc_ok "mise: all tools installed" || _doc_err "mise: $m_missing tools missing — run: $DOTFILES_CMD toolchains"
    (( m_outdated == 0 )) && _doc_ok "mise: tools up to date" || _doc_warn "mise: $m_outdated tools outdated — run: $DOTFILES_CMD update"
  else
    _doc_err "mise not installed"
  fi
  if has rustup && rustup toolchain list 2>/dev/null | grep -q '^stable'; then _doc_ok "rust $(rustc +stable --version 2>/dev/null | awk '{ print $2 }') (stable)"
  else _doc_err "rust stable missing — run: $DOTFILES_CMD toolchains"; fi

  # Two installs of the same tool (like Homebrew texlive next to MacTeX) cause
  # hard-to-debug problems.
  # Flutter / Android: quick checks only (the full `flutter doctor` takes 10-20 s).
  if has flutter; then
    _doc_head "Flutter & Android"
    local dart_v
    dart_v=$(dart --version 2>&1 | sed -n 's/.*SDK version: \([^ ]*\).*/\1/p' || true)
    [[ -n $dart_v ]] && _doc_ok "Flutter SDK works (Dart $dart_v)" || _doc_err "flutter is installed but dart does not run — run: flutter doctor"
    if [[ -x ${ANDROID_HOME:-/nonexistent}/platform-tools/adb ]]; then
      _doc_ok "Android SDK at $(tilde "$ANDROID_HOME")"
    else
      _doc_warn "Android SDK not found at $(tilde "${ANDROID_HOME:-\$ANDROID_HOME}") — only needed for Android builds (install it with Android Studio); details: flutter doctor"
    fi
  fi

  _doc_head "Duplicates on PATH"
  local tool dup=0 copies
  for tool in node npm python3 java go nvim docker pdflatex latexmk; do
    # mise's own copies and the OS's built-in ones (/usr/bin, /bin) don't count.
    copies=$(which -a "$tool" 2>/dev/null | grep -v -E '/mise/(shims|installs)/|^/usr/bin/|^/bin/' | awk '!seen[$0]++' || true)
    if (( $(printf '%s' "$copies" | grep -c . || true) > 1 )); then
      _doc_warn "$tool has several copies: $(printf '%s' "$copies" | tr '\n' ' ')"; dup=1
    fi
  done
  (( dup == 0 )) && _doc_ok "no conflicting copies of key tools"

  _doc_head "Neovim"
  if has nvim; then
    local notes
    notes=$(nvim --headless --cmd "lua _G.__n=0; vim.notify=function(_, l) if (l or 0) >= vim.log.levels.WARN then _G.__n=_G.__n+1 end end" \
      "+lua vim.defer_fn(function() vim.api.nvim_exec_autocmds('User',{pattern='VeryLazy'}); vim.defer_fn(function() io.stdout:write(_G.__n); vim.cmd('qa!') end, 3000) end, 2000)" 2>/dev/null)
    (( ${notes:-1} == 0 )) && _doc_ok "starts without warnings" || _doc_warn "${notes:-?} warnings at startup — open nvim and check :messages"
    local broken
    broken=$(find "$XDG_DATA_HOME/nvim/mason/bin" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
    (( broken == 0 )) && _doc_ok "Mason tools intact" || _doc_err "$broken broken Mason tools — reinstall in :Mason"
  else
    _doc_err "nvim not installed"
  fi

  _doc_head "VS Code"
  if [[ -n $(_vscode_cli) ]]; then
    local vdir vbad=0 vf
    vdir=$(vscode_user_dir)
    for vf in "${VSCODE_FILES[@]}"; do _links_into_repo "$vdir/$vf" || vbad=1; done
    (( vbad == 0 )) && _doc_ok "settings and keybindings linked" || _doc_err "VS Code settings not linked — run: $DOTFILES_CMD link"
    local vmissing
    vmissing=$(comm -23 <(_vscode_wanted | sort) <("$(_vscode_cli)" --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort) | grep -c . || true)
    (( vmissing == 0 )) && _doc_ok "all listed extensions installed" || _doc_warn "$vmissing extensions missing — run: $DOTFILES_CMD shell"
  else
    _doc_warn "VS Code not installed"
  fi

  _doc_head "LaTeX"
  if has latexmk; then
    biber --version >/dev/null 2>&1 && _doc_ok "biber works" || _doc_err "biber fails — run: $DOTFILES_CMD toolchains"
    printf '%s\n' '\begin{document}x\end{document}' | latexindent -g /dev/null - >/dev/null 2>&1 && _doc_ok "latexindent works" || _doc_err "latexindent fails — run: $DOTFILES_CMD toolchains"
  else
    _doc_warn "TeX Live not installed — run: $DOTFILES_CMD packages"
  fi

  _doc_head "Docker"
  if has docker; then
    docker info >/dev/null 2>&1 && _doc_ok "docker daemon reachable" || _doc_warn "docker installed, daemon not running"
  else
    _doc_err "docker not installed"
  fi

  printf '\n%s%d ok · %d warnings · %d errors%s\n' "$_c_bold" "$_DOC_OK" "$_DOC_WARN" "$_DOC_ERR" "$_c_reset"
  (( _DOC_ERR == 0 ))
}

# --- update --------------------------------------------------------------------

# Every update step, in the order they run. `dotctl update <step>…` picks some;
# without names an interactive menu asks (Enter alone runs them all).
# shellcheck disable=SC2034  # read by bootstrap.sh
UPDATE_STEP_NAMES=(system mise rust tldr zsh tmux nvim texlive)

# The steps that apply on this machine, as parallel arrays: name, label, details.
_update_collect() {
  _U_NAMES=() _U_LABELS=() _U_DESCS=()
  local sys
  case $DOTFILES_OS in
    macos) sys=Homebrew ;; arch) sys=pacman ;; fedora) sys=dnf ;; debian) sys=apt ;;
  esac
  _update_add system  "$sys"          "system packages"
  if is_linux; then _update_add mise "mise" "mise itself and its tools"
  else _update_add mise "mise" "tools (Java, Node, Python, Go, …)"; fi
  _update_add rust    "Rust"          "rustup stable toolchain"
  if has tldr; then _update_add tldr "tldr pages" "offline command examples"; fi
  _update_add zsh     "zsh plugins"   "antidote"
  _update_add tmux    "tmux plugins"  "tpm"
  _update_add nvim    "Neovim"        "plugins, treesitter parsers, Mason tools"
  if is_macos && has tlmgr; then _update_add texlive "TeX Live" "tlmgr (asks for your password)"; fi
}
_update_add() { _U_NAMES+=("$1"); _U_LABELS+=("$2"); _U_DESCS+=("$3"); }

update_all() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  _mise_env
  _update_collect
  local chosen=() name i requested=" ${UPDATE_STEPS[*]:-} "
  if [[ ${#UPDATE_STEPS[@]} -gt 0 ]]; then
    for name in "${UPDATE_STEPS[@]}"; do
      [[ " ${_U_NAMES[*]} " == *" $name "* ]] || warn "$name: not available on this machine, skipped"
    done
    for name in "${_U_NAMES[@]}"; do [[ $requested == *" $name "* ]] && chosen+=("$name"); done
  elif [[ $ASSUME_YES != 1 && -t 0 && -t 1 ]]; then
    _update_menu
    for ((i = 0; i < ${#_U_NAMES[@]}; i++)); do [[ ${_U_SEL[i]} == 1 ]] && chosen+=("${_U_NAMES[i]}"); done
  else
    chosen=("${_U_NAMES[@]}")
  fi
  if [[ ${#chosen[@]} -eq 0 ]]; then info "nothing selected, nothing updated"; return 0; fi

  _UPDATE_RESULTS=()
  for name in "${chosen[@]}"; do _update_run "$name"; done

  step "Summary"
  local r; for r in "${_UPDATE_RESULTS[@]}"; do printf '  %s\n' "$r"; done
  if ! git -C "$DOTFILES" diff --quiet -- home/nvim/.config/nvim/lazy-lock.json 2>/dev/null; then
    info "lazy-lock.json changed — commit it so other machines get the same plugins (dots)"
  fi
}

_update_run() {
  case $1 in
    system)
      case $DOTFILES_OS in
        macos)  _upd "Homebrew" run sh -c 'brew update && brew upgrade' ;;
        arch)   _upd "pacman"   as_root pacman -Syu --noconfirm ;;
        fedora) _upd "dnf"      as_root dnf -y upgrade ;;
        debian) _upd "apt"      _apt_upgrade ;;
      esac ;;
    mise)
      if is_linux && [[ -x $HOME/.local/bin/mise ]]; then _upd "mise itself" run "$HOME/.local/bin/mise" self-update --yes; fi
      _upd "mise tools" run "$(_mise_bin)" upgrade --yes ;;
    rust)    _upd "Rust"         run rustup update ;;
    tldr)    _upd "tldr pages"   run tldr --update ;;
    zsh)     _upd "zsh plugins"  _update_zsh_plugins ;;
    tmux)    _upd "tmux plugins" _update_tmux_plugins ;;
    nvim)    _upd "Neovim"       _update_nvim ;;
    texlive) _upd "TeX Live"     _update_texlive ;;
  esac
}

# Checklist on the terminal, every step ticked: ↑/↓ or j/k move, space ticks,
# a ticks all or none, enter runs the ticked steps, q or esc cancels (none).
# Leaves the choice in _U_SEL (1 = run).
_update_menu() {
  local n=${#_U_NAMES[@]} cur=0 key rest i all
  _U_SEL=(); for ((i = 0; i < n; i++)); do _U_SEL[i]=1; done
  printf '\n%sChoose what to update%s  %s\n' "$_c_bold" "$_c_reset" \
    "$(hint '↑↓ move · space select · a all/none · enter update · q cancel')"
  local tty; tty=$(stty -g)
  stty -echo                             # keys pressed between redraws stay off screen
  printf '\e[?25l'                       # hide the cursor while the menu is up
  trap 'stty "$tty"; printf "\e[?25h"; exit 130' INT
  _update_menu_draw "$cur"
  while :; do
    IFS= read -rsn1 key || key=q
    if [[ $key == $'\e' ]]; then         # arrow keys arrive as ESC [ A/B
      IFS= read -rsn2 -t 1 rest || rest=""
      case $rest in '[A') key=k ;; '[B') key=j ;; *) key=q ;; esac
    fi
    case $key in
      k) cur=$(( (cur + n - 1) % n )) ;;
      j) cur=$(( (cur + 1) % n )) ;;
      ' ') _U_SEL[cur]=$(( 1 - _U_SEL[cur] )) ;;
      a) all=1; for ((i = 0; i < n; i++)); do [[ ${_U_SEL[i]} == 1 ]] || all=0; done
         for ((i = 0; i < n; i++)); do _U_SEL[i]=$(( 1 - all )); done ;;
      '') break ;;
      q) for ((i = 0; i < n; i++)); do _U_SEL[i]=0; done; break ;;
      *) continue ;;
    esac
    printf '\e[%dA' "$n"                 # back to the first row and redraw
    _update_menu_draw "$cur"
  done
  stty "$tty"; printf '\e[?25h'
  trap - INT
}

_update_menu_draw() {
  local cur=$1 i box ptr label
  for ((i = 0; i < ${#_U_NAMES[@]}; i++)); do
    if [[ ${_U_SEL[i]} == 1 ]]; then box="${_c_green}[x]${_c_reset}"; else box="[ ]"; fi
    printf -v label '%-13s' "${_U_LABELS[i]}"
    if (( i == cur )); then ptr="${_c_blue}❯${_c_reset}"; label="${_c_bold}${label}${_c_reset}"; else ptr=" "; fi
    printf '\e[2K  %s %s %s %s\n' "$ptr" "$box" "$label" "$(hint "${_U_DESCS[i]}")"
  done
}

# Run one update step and record its result for the summary.
_upd() {
  local label=$1 t0=$SECONDS; shift
  step "$label"
  if "$@"; then
    _UPDATE_RESULTS+=("$(printf '%s✓%s %-14s %s' "$_c_green" "$_c_reset" "$label" "$(human_time $((SECONDS - t0)))")")
  else
    _UPDATE_RESULTS+=("$(printf '%s✗%s %-14s failed — see above' "$_c_red" "$_c_reset" "$label")")
  fi
}

_apt_upgrade() { as_root apt-get update -qq && as_root apt-get upgrade -y; }

_update_zsh_plugins() {
  local antidote="$XDG_DATA_HOME/antidote"
  [[ -d $antidote ]] || { warn "antidote not installed"; return 1; }
  run zsh -c "source '$antidote/antidote.zsh' && antidote update"
  # Rebuild the static bundles on the next shell start.
  run rm -f "$XDG_CACHE_HOME/zsh/plugins.zsh" "$XDG_CACHE_HOME/zsh/plugins.post.zsh"
}

_update_tmux_plugins() {
  local tpm="$XDG_DATA_HOME/tmux/plugins/tpm"
  [[ -x $tpm/bin/update_plugins ]] || { warn "tpm not installed"; return 1; }
  run env TMUX_PLUGIN_MANAGER_PATH="$XDG_DATA_HOME/tmux/plugins/" "$tpm/bin/update_plugins" all
}

# Plugins (and lazy-lock.json), treesitter parsers, Mason tools — in that order,
# because new plugin versions can need newer parsers.
_update_nvim() {
  has nvim || { warn "nvim not installed"; return 1; }
  info "plugins…";          run nvim --headless "+Lazy! sync" +qa
  info "treesitter parsers…"
  run nvim --headless "+lua local ok, ts = pcall(require, 'nvim-treesitter'); if ok and ts.update then ts.update():wait(900000) end; vim.cmd('qa!')"
  info "Mason tools…"
  run nvim --headless "+lua vim.defer_fn(function()
    require('lazy').load({ plugins = { 'mason.nvim' } })
    local reg = require('mason-registry')
    -- Mason's callbacks run in a fast event context, where Ex commands like
    -- :qa are not allowed; vim.schedule hands each step back to the main loop.
    reg.refresh(vim.schedule_wrap(function()
      local todo, failed = {}, {}
      for _, p in ipairs(reg.get_installed_packages()) do
        local ok, latest = pcall(p.get_latest_version, p)
        if ok and latest and p:get_installed_version() ~= latest then table.insert(todo, p) end
      end
      local i = 0
      local function next_one()
        i = i + 1
        if i > #todo then
          if #failed > 0 then
            io.stdout:write('  could not download: ' .. table.concat(failed, ', ') .. ' (Mason registry issue; the installed version is kept)\n')
          end
          vim.cmd('qa!')
          return
        end
        local p = todo[i]
        p:install({}, vim.schedule_wrap(function(success)
          if success then io.stdout:write('  updated ' .. p.name .. '\n') else table.insert(failed, p.name) end
          next_one()
        end))
      end
      if #todo == 0 then io.stdout:write('  all Mason tools up to date\n') end
      next_one()
    end))
  end, 1000)"
}

# TeX Live on macOS (MacTeX) updates through tlmgr, which needs sudo.
_update_texlive() {
  run sudo tlmgr update --self --all
  setup_latex   # re-extract biber if the update replaced it
}

# --- prune ---------------------------------------------------------------------

# List what is installed but not managed by the repo; remove it with -y.
# Never touches App Store apps, taps, or packages other packages depend on.
prune() {
  local remove=${ASSUME_YES:-0} found=0 line
  if is_macos; then
    # Only formulae you installed yourself (leaves) and casks that are in neither
    # Brewfile. Dependencies are left to `brew autoremove`; App Store apps and
    # taps are never touched (`brew bundle cleanup` would remove those too).
    local wanted name formulae=() casks=()
    wanted=" $(sed -nE 's/^(brew|cask) "([^"]+)".*/\2/p' "$DOTFILES/packages/Brewfile" "$DOTFILES/packages/Brewfile.extra" | sed 's|.*/||' | tr '\n' ' ') "
    while IFS= read -r name; do
      [[ -n $name && $wanted != *" ${name##*/} "* ]] && formulae+=("$name")
    done < <(brew leaves --installed-on-request 2>/dev/null)
    local current
    while IFS= read -r name; do
      [[ -n $name && $wanted != *" $name "* ]] || continue
      # Renamed casks (e.g. wireshark → wireshark-app) are listed under their new name.
      current=$(brew info --cask "$name" 2>/dev/null | sed -n '1s/^==> \([^ ]*\).*/\1/p')
      [[ -n $current && $wanted == *" $current "* ]] && continue
      casks+=("$name")
    done < <(brew list --cask -1 2>/dev/null)

    if [[ ${#formulae[@]} -gt 0 ]]; then
      found=1; info "Homebrew formulae you installed that neither Brewfile lists:"; columns "${formulae[@]}"
    fi
    if [[ ${#casks[@]} -gt 0 ]]; then
      found=1; info "Homebrew casks that neither Brewfile lists:"; columns "${casks[@]}"
    fi
    if [[ ${#formulae[@]} -eq 0 && ${#casks[@]} -eq 0 ]]; then
      ok "Homebrew: nothing outside the Brewfiles"
    elif [[ $remove == 1 ]]; then
      [[ ${#formulae[@]} -gt 0 ]] && run brew uninstall --formula "${formulae[@]}"
      [[ ${#casks[@]} -gt 0 ]] && run brew uninstall --cask "${casks[@]}"
      run brew autoremove   # dependencies nothing needs anymore
    fi
  fi
  local extra_ext=()
  while IFS= read -r line; do [[ -n $line ]] && extra_ext+=("$line"); done < <(vscode_extra_extensions)
  if [[ ${#extra_ext[@]} -gt 0 ]]; then
    found=1
    info "VS Code extensions not in vscode/extensions.txt:"
    columns "${extra_ext[@]}"
    if [[ $remove == 1 ]]; then
      local cli; cli=$(_vscode_cli)
      for line in "${extra_ext[@]}"; do run "$cli" --uninstall-extension "$line" >/dev/null 2>&1 || warn "could not remove $line"; done
    fi
  else
    ok "VS Code: no extensions outside the list"
  fi

  local mise unused=() line
  mise=$(_mise_bin)
  _mise_env
  while IFS= read -r line; do [[ -n $line ]] && unused+=("$line"); done \
    < <("$mise" prune --dry-run 2>&1 | grep -o 'mise [^ ]* is prunable' | awk '{ print $2 }' | sort -u || true)
  if [[ ${#unused[@]} -gt 0 ]]; then
    found=1
    info "mise tool versions no config uses:"
    columns "${unused[@]}"
    [[ $remove == 1 ]] && run "$mise" prune --yes
  else
    ok "mise: no unused tool versions"
  fi
  if [[ $found == 1 && $remove != 1 ]]; then
    info "nothing removed — run $DOTFILES_CMD prune -y to remove the items above"
  fi
}
