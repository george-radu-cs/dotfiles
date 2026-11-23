# shellcheck shell=bash
# Language toolchains.
#   mise   → java (11/17/21/25), node, bun, python, uv  (+ Go, TypeScript, CLI tools on Linux)
#   rustup → rust stable + cargo, clippy, rustfmt, rust-analyzer (official
#            installer from rust-lang.org on every OS; updates: rustup update)
#   C/C++, Lua → system packages step

_mise() {
  local bin
  bin=$(command -v mise || echo "$HOME/.local/bin/mise")
  if is_linux; then MISE_ENV=linux run "$bin" "$@"; else run "$bin" "$@"; fi
}

install_toolchains() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  _install_mise_tools
  _install_rust
  setup_latex
  # shellcheck disable=SC2154  # set by setup_latex (lib/latex.sh)
  note "$_mise_summary · rust $_rust_version · $_latex_summary"
}

# mise: install only when something is missing; otherwise one summary line.
_install_mise_tools() {
  _mise_summary="mise tools"
  if ! has mise && [[ ! -x $HOME/.local/bin/mise ]]; then
    # In a dry run the packages step only printed its install, so mise may not exist yet.
    [[ $DRY_RUN == 1 ]] || die "mise missing (run the packages step first)"
    run mise install --yes
    return
  fi
  local bin missing
  bin=$(command -v mise || echo "$HOME/.local/bin/mise")
  is_linux && export MISE_ENV=linux
  "$bin" trust --yes --all >/dev/null 2>&1 || true
  missing=$("$bin" ls 2>/dev/null | awk '/\(missing\)/ { print $1 }' | sort -u | tr '\n' ' ')

  if [[ -n $missing ]]; then
    info "mise: installing ${missing% }  (first run downloads several JDKs)…"
    run "$bin" install --yes
  fi
  # "java ×5 · node 26.13.1 · bun 1.4.5 · …" from `mise ls`
  local summary
  summary=$("$bin" ls 2>/dev/null | awk '
    !/\(missing\)/ { n[$1]++; if (!($1 in v)) { v[$1] = $2; order[++k] = $1 } }
    END { for (i = 1; i <= k; i++) { t = order[i]
            out = out (i > 1 ? " · " : "") t " " (n[t] > 1 ? "×" n[t] : v[t]) }
          print out }')
  ok "mise: ${summary:-no tools}"
  _mise_summary="${summary:-mise}"
}

# rustup: install/repair only when stable or a component is missing.
_install_rust() {
  _rust_version="stable"
  local want=(rust-analyzer clippy rustfmt) have missing=() c
  if has rustup && rustup toolchain list 2>/dev/null | grep -q '^stable'; then
    have=$(rustup component list --installed --toolchain stable 2>/dev/null)
    for c in "${want[@]}"; do grep -q "^$c" <<<"$have" || missing+=("$c"); done
    if [[ ${#missing[@]} -gt 0 ]]; then
      info "rust: adding ${missing[*]}…"
      run rustup component add --toolchain stable "${missing[@]}"
    fi
  else
    if ! has rustup; then
      info "rust: installing rustup (official installer from rust-lang.org)…"
      if [[ $DRY_RUN == 1 ]]; then
        run sh -c 'curl https://sh.rustup.rs | sh -s -- -y --no-modify-path'
      else
        curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile default
      fi
    fi
    run rustup toolchain install stable --profile default
    run rustup component add --toolchain stable "${want[@]}"
  fi
  if has rustc; then _rust_version=$(rustc +stable --version 2>/dev/null | awk '{ print $2 }'); fi
  ok "rust ${_rust_version} (stable) · ${want[*]}   $(hint "update with: rustup update")"
}
