set nocompatible

filetype plugin indent on
syntax enable
packadd! matchit

set number
set ruler
set showcmd
set showmatch
set hidden
set mouse=a
set clipboard=unnamed
set splitbelow
set splitright
set incsearch
set hlsearch
set ignorecase
set smartcase
set wildmenu
set wildmode=longest:full,full
set completeopt=menuone,noselect,popup
set updatetime=300
set signcolumn=yes
set cursorline
set list
set listchars=tab:>-,trail:.,extends:>,precedes:<,nbsp:+
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set smartindent
set backspace=indent,eol,start
set undofile

if has('termguicolors')
  set termguicolors
endif

let s:undo_dir = expand('~/.local/state/vim/undo')
if !isdirectory(s:undo_dir)
  call mkdir(s:undo_dir, 'p')
endif
let &undodir = s:undo_dir

augroup dotfiles_filetypes
  autocmd!
  autocmd FileType gitcommit setlocal spell textwidth=72
  autocmd FileType markdown setlocal spell
augroup END
