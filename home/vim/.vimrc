syntax on

set guicursor=
set noshowmatch
set nohlsearch
set hidden
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set relativenumber
set nu
set cursorline
set wrap
set smartcase
set noswapfile
set nobackup
set nowritebackup
set undodir=~/.local/state/vim/undo//
set undofile
set incsearch
set termguicolors
set scrolloff=8
set noshowmode

set wildmenu
set encoding=UTF-8
set laststatus=2
set history=1000
set ttimeout ttimeoutlen=50
filetype plugin on

" Give more space for displaying messages.
set cmdheight=2

" Having longer updatetime (default is 4000 ms = 4 s) leads to noticeable
" delays and poor user experience.
set updatetime=300

" Don't pass messages to |ins-completion-menu|.
set shortmess+=c
set signcolumn=yes
set colorcolumn=80
set background=dark
" retrobox = gruvbox-like scheme bundled with Vim 9; falls back silently on older vims
silent! colorscheme retrobox

if !isdirectory(expand('~/.local/state/vim/undo'))
  call mkdir(expand('~/.local/state/vim/undo'), 'p')
endif
set viminfofile=~/.local/state/vim/viminfo
