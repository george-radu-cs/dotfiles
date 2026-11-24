# shellcheck shell=bash
# shellcheck disable=SC2154  # colour variables come from lib/common.sh
# shellcheck disable=SC2015  # `check && ok || err`: the ok/warn helpers always succeed
# Keeping an installed machine healthy:
#   doctor   read-only health report (links, packages, toolchains, Neovim, LaTeX…)
#   update   upgrade everything the repo manages, in one go
#   prune    list (and with -y remove) what is installed but no longer managed

_DOC_OK=0 _DOC_WARN=0 _DOC_ERR=0
_doc_ok()   { ok "$*";   _DOC_OK=$((_DOC_OK + 1)); }
_doc_warn() { warn "$*"; _DOC_WARN=$((_DOC_WARN + 1)); }
_doc_err()  { printf '  %s✗%s %s\n' "$_c_red" "$_c_reset" "$*"; _DOC_ERR=$((_DOC_ERR + 1)); }
_doc_head() { printf '\n%s%s%s\n' "$_c_bold" "$*" "$_c_reset"; }

_mise_bin() { command -v mise || echo "$HOME/.local/bin/mise"; }

# --- doctor --------------------------------------------------------------------

doctor() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

  _doc_head "Links"
  local missing
  missing=$(check_links 2>&1 | grep -c "not linked" || true)
  if (( missing == 0 )); then _doc_ok "all ${#LINK_PACKAGES[@]} packages linked"
  else _doc_err "$missing files not linked — run: ./bootstrap.sh link"; fi

  _doc_head "Shell"
  if [[ $(basename "${SHELL:-}") == zsh ]]; then _doc_ok "login shell is zsh"; else _doc_warn "login shell is ${SHELL:-unknown}, not zsh"; fi
  local ms
  ms=$( { /usr/bin/time -p zsh -i -c exit >/dev/null; } 2>&1 | awk '/real/ { printf "%d", $2 * 1000 }')
  if (( ${ms:-9999} < 300 )); then _doc_ok "zsh starts in ${ms} ms"; else _doc_warn "zsh starts in ${ms:-?} ms (profile with: ZPROF=1 zsh -i -c exit)"; fi

  _doc_head "Packages"
  if is_macos; then
    local brew_missing
    brew_missing=$(brew bundle check --no-upgrade --verbose --file "$DOTFILES/packages/Brewfile" 2>&1 | grep -c '^→' || true)
    if (( brew_missing == 0 )); then _doc_ok "Brewfile satisfied"
    else _doc_warn "$brew_missing Brewfile entries missing — run: ./bootstrap.sh packages"; fi
    local outdated
    outdated=$(brew outdated --quiet 2>/dev/null | wc -l | tr -d ' ')
    (( outdated == 0 )) && _doc_ok "Homebrew packages up to date" || _doc_warn "$outdated Homebrew packages outdated — run: ./bootstrap.sh update"
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
    (( m_missing == 0 )) && _doc_ok "mise: all tools installed" || _doc_err "mise: $m_missing tools missing — run: ./bootstrap.sh toolchains"
    (( m_outdated == 0 )) && _doc_ok "mise: tools up to date" || _doc_warn "mise: $m_outdated tools outdated — run: ./bootstrap.sh update"
  else
    _doc_err "mise not installed"
  fi
  if has rustup && rustup toolchain list 2>/dev/null | grep -q '^stable'; then _doc_ok "rust $(rustc +stable --version 2>/dev/null | awk '{ print $2 }') (stable)"
  else _doc_err "rust stable missing — run: ./bootstrap.sh toolchains"; fi

  # Two installs of the same tool (like Homebrew texlive next to MacTeX) cause
  # hard-to-debug problems.
  _doc_head "Duplicates on PATH"
  local tool dup=0 copies
  for tool in node npm python3 java go nvim docker pdflatex latexmk; do
    # mise's own copies and the OS's built-in ones (/usr/bin, /bin) don't count.
    copies=$(which -a "$tool" 2>/dev/null | grep -v -E '/mise/(shims|installs)/|^/usr/bin/|^/bin/' | awk '!seen[$0]++')
    if (( $(printf '%s' "$copies" | grep -c .) > 1 )); then
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

  _doc_head "LaTeX"
  if has latexmk; then
    biber --version >/dev/null 2>&1 && _doc_ok "biber works" || _doc_err "biber fails — run: ./bootstrap.sh toolchains"
    printf '%s\n' '\begin{document}x\end{document}' | latexindent -g /dev/null - >/dev/null 2>&1 && _doc_ok "latexindent works" || _doc_err "latexindent fails — run: ./bootstrap.sh toolchains"
  else
    _doc_warn "TeX Live not installed — run: ./bootstrap.sh packages"
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

update_all() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  _UPDATE_RESULTS=()
  case $DOTFILES_OS in
    macos)  _upd "Homebrew"       run sh -c 'brew update && brew upgrade' ;;
    arch)   _upd "pacman"         as_root pacman -Syu --noconfirm ;;
    fedora) _upd "dnf"            as_root dnf -y upgrade ;;
    debian) _upd "apt"            _apt_upgrade ;;
  esac
  if is_linux && [[ -x $HOME/.local/bin/mise ]]; then _upd "mise itself" run "$HOME/.local/bin/mise" self-update --yes; fi
  _upd "mise tools"       run "$(_mise_bin)" upgrade --yes
  _upd "Rust"             run rustup update
  _upd "zsh plugins"      _update_zsh_plugins
  _upd "tmux plugins"     _update_tmux_plugins
  _upd "Neovim"           _update_nvim
  is_macos && has tlmgr && _upd "TeX Live" _update_texlive

  step "Summary"
  local r; for r in "${_UPDATE_RESULTS[@]}"; do printf '  %s\n' "$r"; done
  if ! git -C "$DOTFILES" diff --quiet -- home/nvim/.config/nvim/lazy-lock.json 2>/dev/null; then
    info "lazy-lock.json changed — commit it so other machines get the same plugins (dots)"
  fi
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
    reg.refresh(function()
      local todo = {}
      for _, p in ipairs(reg.get_installed_packages()) do
        local ok, latest = pcall(p.get_latest_version, p)
        if ok and latest and p:get_installed_version() ~= latest then table.insert(todo, p) end
      end
      local i = 0
      local function next_one()
        i = i + 1
        if i > #todo then vim.cmd('qa!') return end
        local p = todo[i]
        p:install({}, function(success) io.stdout:write((success and '  updated ' or '  failed  ') .. p.name .. '\n'); next_one() end)
      end
      next_one()
    end)
  end, 1000)"
}

# TeX Live on macOS (MacTeX) updates through tlmgr, which needs sudo.
_update_texlive() {
  run sudo tlmgr update --self --all
  setup_latex   # re-extract biber if the update replaced it
}

# --- prune ---------------------------------------------------------------------

# List what is installed but not managed by the repo; remove it with -y.
prune() {
  local remove=${ASSUME_YES:-0} found=0 line
  if is_macos; then
    local all="$XDG_CACHE_HOME/dotfiles-Brewfile.all"
    mkdir -p "$(dirname "$all")"
    cat "$DOTFILES/packages/Brewfile" "$DOTFILES/packages/Brewfile.extra" >"$all"
    local list=() out err="$XDG_CACHE_HOME/dotfiles-prune.err"
    # brew bundle cleanup exits 1 both when it finds packages and when it fails,
    # so tell them apart by its error output.
    out=$(brew bundle cleanup --file "$all" 2>"$err") || true
    if grep -q '^Error:' "$err"; then
      warn "Homebrew check failed:"
      grep -A1 '^Error:' "$err" | sed 's/^/      /' >&2
      found=1
    fi
    while IFS= read -r line; do [[ -n $line ]] && list+=("$line"); done \
      < <(printf '%s\n' "$out" | grep -v -E '^(Would|Run)' || true)
    if grep -q '^Error:' "$err"; then
      :
    elif [[ ${#list[@]} -gt 0 ]]; then
      found=1
      info "Homebrew packages not in Brewfile or Brewfile.extra:"
      columns "${list[@]}"
      if [[ $remove == 1 ]]; then run brew bundle cleanup --force --file "$all"; run brew autoremove; fi
    else
      ok "Homebrew: nothing outside the Brewfiles"
    fi
  fi
  local mise unused=() line
  mise=$(_mise_bin)
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
    info "nothing removed — run ./bootstrap.sh prune -y to remove the items above"
  fi
}
