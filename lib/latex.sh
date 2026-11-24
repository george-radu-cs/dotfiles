# shellcheck shell=bash
# LaTeX: TeX Live comes from the packages step (MacTeX on macOS, distro TeX Live
# on Linux). This makes the rest of the toolchain work:
#   latexindent  needs the Perl modules YAML::Tiny and File::HomeDir
#   Skim         (macOS) jumps back to Neovim on Shift-Cmd-click (SyncTeX)
# latexmk, zathura and vimtex settings come from home/latex and home/nvim.

LATEX_PERL_LIB="$XDG_DATA_HOME/perl5"

setup_latex() {
  _latex_summary="LaTeX"
  if ! has latexmk; then
    warn "LaTeX: latexmk not found (the packages step installs TeX Live)"
    _latex_summary="LaTeX not installed"
    return
  fi

  # latexindent (formatter used by texlab/Neovim) needs two pure-Perl modules.
  export PERL5LIB="$LATEX_PERL_LIB/lib/perl5${PERL5LIB:+:$PERL5LIB}"
  if ! perl -MYAML::Tiny -MFile::HomeDir -e 1 2>/dev/null; then
    if is_macos && has cpanm; then
      info "LaTeX: installing Perl modules for latexindent into $(tilde "$LATEX_PERL_LIB")…"
      run cpanm --quiet --notest --local-lib "$LATEX_PERL_LIB" YAML::Tiny File::HomeDir
    else
      warn "LaTeX: latexindent needs the Perl modules YAML::Tiny and File::HomeDir (packages step)"
    fi
  fi

  # Skim: reload the PDF when it changes, and Shift-Cmd-click opens the line in Neovim.
  if is_macos && [[ -d /Applications/Skim.app ]]; then
    run defaults write -app Skim SKAutoReloadFileUpdate -bool true
    run defaults write -app Skim SKTeXEditorPreset -string "Custom"
    run defaults write -app Skim SKTeXEditorCommand -string "nvim"
    run defaults write -app Skim SKTeXEditorArguments -string "--headless -c \"VimtexInverseSearch %line '%file'\""
  fi

  is_macos && _fix_biber

  local version viewer
  version=$(tex --version 2>/dev/null | sed -n 's/.*(\(TeX Live [0-9]*\).*/\1/p' | head -n 1)
  if is_macos; then viewer=Skim; else viewer=zathura; fi
  ok "LaTeX: ${version:-TeX Live} · latexmk · biber · latexindent · viewer $viewer"
  _latex_summary="${version:-TeX Live}"
}

# MacTeX's biber launcher unpacks its Apple Silicon build with
# `lipo -extract_family`, an option current Xcode versions no longer accept, so
# biber fails ("extracting arm64 binary with lipo failed"). The binary inside is
# fine: extract it with plain `lipo -thin` into ~/.local/bin, which comes before
# /Library/TeX/texbin in PATH. Re-extracted when TeX Live updates biber, and
# removed again once TeX Live's own biber works.
_fix_biber() {
  local tl=/Library/TeX/texbin/biber fixed="$HOME/.local/bin/biber"
  [[ -x $tl && $(uname -m) == arm64 ]] || return 0
  if "$tl" --version >/dev/null 2>&1; then
    if [[ -f $fixed ]]; then run rm -f "$fixed"; info "LaTeX: TeX Live's biber works again, removed the extracted copy"; fi
    return 0
  fi
  if [[ ! -x $fixed || $tl -nt $fixed ]]; then
    run mkdir -p "$(dirname "$fixed")"
    run lipo "$tl" -thin arm64 -output "$fixed" || true
    if [[ $DRY_RUN == 1 ]] || "$fixed" --version >/dev/null 2>&1; then
      ok "LaTeX: biber extracted to $(tilde "$fixed") (TeX Live's launcher fails with this Xcode)"
    else
      run rm -f "$fixed"
      warn "LaTeX: biber does not work and could not be repaired — bibliographies with biblatex will fail"
    fi
  fi
}
