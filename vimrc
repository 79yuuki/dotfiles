" Setting for NeoBundle
 if has('vim_starting')
   set nocompatible               " Be iMproved

   " Required:
   set runtimepath+=~/.vim/bundle/neobundle.vim/
 endif

 " Required:
 call neobundle#rc(expand('~/.vim/bundle/'))

" originalrepos on github
 NeoBundle 'Shougo/neobundle.vim'
 NeoBundle 'Shougo/vimproc'
 NeoBundle 'VimClojure'
 NeoBundle 'Shougo/vimshell'
 NeoBundle 'Shougo/unite.vim'
 NeoBundle 'Shougo/neocomplcache'
 NeoBundle 'Shougo/neosnippet'
 NeoBundle 'Shougo/neosnippet-snippets'
 NeoBundle 'jpalardy/vim-slime'
 NeoBundle 'scrooloose/syntastic'

 NeoBundle 'itchyny/lightline.vim'

" NerdTree
 NeoBundle 'scrooloose/nerdtree'
" NerdTree Tabs
" NeoBundle 'jistr/vim-nerdtree-tabs'

" vim-fugitive
 NeoBundle 'tpope/vim-fugitive'
 NeoBundle 'gregsexton/gitv.git'
" GitGutter
 NeoBundle 'airblade/vim-gitgutter'

" Syntastic
 NeoBundle 'scrooloose/syntastic'
" Tagbar
 NeoBundle 'majutsushi/tagbar'

" Vim Over
 NeoBundle 'osyo-manga/vim-over'
" Dash.app
" NeoBundle 'rizzatti/funcoo.vim'
" NeoBundle 'rizzatti/dash.vim'

" Vim Multi cursor
" NeoBundle 'terryma/vim-multiple-cursors'

" YankRing
 NeoBundle 'LeafCage/yankround.vim'

" ChooseWin
 NeoBundle 't9md/vim-choosewin'

" Quick-Run
 NeoBundle "thinca/vim-quickrun"
" Open Browser
 NeoBundle 'tyru/open-browser.vim'

" Indent
 NeoBundle 'nathanaelkane/vim-indent-guides'
" neocomplcache
" NeoBundle 'Shougo/neocomplcache.vim'
" NeoBundle 'Shougo/neocomplete.vim'
" NeoBundle 'Shougo/neosnippet.vim'
" tern
 NeoBundle 'marijnh/tern_for_vim'

"NeoBundle 'suguru/vim-javascript-syntax'
"NeoBundle 'jelera/vim-javascript-syntax'
 NeoBundle 'pangloss/vim-javascript'
"NeoBundle 'nathanaelkane/vim-indent-guides'
"NeoBundle 'jiangmiao/simple-javascript-indenter'

" Coffeescript
 NeoBundle 'kchmck/vim-coffee-script'

" Node.js
"NeoBundle 'myhere/vim-nodejs-complete'

" CSS3
 NeoBundle 'hail2u/vim-css3-syntax'
" Jade
 NeoBundle 'digitaltoad/vim-jade'
" Stylus
 NeoBundle 'wavded/vim-stylus'
" Yaml
 NeoBundle 'stephpy/vim-yaml'
" Markdonw
 NeoBundle 'tpope/vim-markdown'

" Markdonw preview
 NeoBundle 'kannokanno/previm'

" color table
" NeoBundle "guns/xterm-color-table.vim"
"
 NeoBundle 'editorconfig/editorconfig-vim'


" CtrlP
" NeoBundle "kien/ctrlp.vim"

 " Syntastic
 NeoBundle 'scrooloose/syntastic'

" Color Schemes
 NeoBundle 'goatslacker/mango.vim'

""NeoBundle 'https://bitbucket.org/kovisoft/slimv'

filetype plugin indent on     " required!
filetype indent on
syntax on

" ====================
" generic options
" ====================
set nobackup
set noswapfile
set incsearch

" ====================
" visual options
" ====================
filetype plugin indent on
set showmode
set title
set ruler
set showcmd
set showmatch
set laststatus=2
set cursorline
set ttyfast
" cursor
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
" spaces
set list
set listchars=tab:»-,trail:-,nbsp:%,extends:>,precedes:<


if has("syntax")
  syntax on

  syn sync fromstart
  function! ActivateInvisibleIndicator()
    syntax match InvisibleJISX0208Space "　" display containedin=ALL
    highlight InvisibleJISX0208Space term=underline ctermbg=Blue guibg=darkgray gui=underline
    "syntax match InvisibleTrailedSpace "[ \t]\+$" display containedin=ALL
    "highlight InvisibleTrailedSpace term=underline ctermbg=Red guibg=NONE gui=undercurl guisp=darkorange
    "syntax match InvisibleTab "\t" display containedin=ALL
    "highlight InvisibleTab term=underline ctermbg=white gui=undercurl guisp=darkslategray
  endfunction

  augroup invisible
    autocmd! invisible
    autocmd BufNew,BufRead * call ActivateInvisibleIndicator()
  augroup END
endif

" ====================
" programming
" ====================
set cindent
set smartcase
set wrapscan
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set backspace=indent,eol,start

" ====================
" mouse options
" ====================
if has("mouse")
  set mouse=a
endif


" ====================
" color scheme
" ====================
syntax enable
set t_Co=256
set background=dark
color mango
"colorscheme proteus
"colorscheme molokai
"colorscheme desert
"colorscheme distinguished

" Adjust omnifunc pop menu
highlight Pmenu ctermbg=179 ctermfg=16 cterm=bold
highlight CursorLine ctermbg=237
" Color Scheme for javascript
highlight jsFunction ctermfg=105
highlight jsFuncName ctermfg=111
highlight jsFuncArgs ctermfg=211
highlight jsObjectKey ctermfg=141
highlight jsFunctionKey ctermfg=141
highlight Noise ctermfg=216

" ====================
" file types
" ====================
au! BufRead,BufNewFile *.json set filetype=javascript


" ====================
" Syntastic
" ====================
let g:syntastic_enable_signs=1
"let g:syntastic_auto_jump=1
"let g:syntastic_check_on_open=1w
let g:syntastic_auto_loc_list=1
let g:syntastic_mode_map={
      \ 'mode': 'active',
      \ 'active_filetypes': ['javascript'],
      \ 'passive_filetypes': ['html','cpp']
      \}
let g:syntastic_javascript_checkers = ['jshint']



" ====================
" ctrlp
" ====================
"let g:ctrlp_use_migemo = 1
"let g:ctrlp_clear_cache_on_exit = 0
"let g:ctrlp_mruf_max            = 500
"" let g:ctrlp_open_new_file       = 1


" ====================
" vim-indent-guides
" ====================
let g:indent_guides_auto_colors=0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd   ctermbg=234
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven  ctermbg=240
let g:indent_guides_enable_on_vim_startup=2
let g:indent_guides_guide_size=1


"" old settings
"set nocompatible
"set history=50
"set ignorecase
"set smartcase
"set wrapscan
"set hlsearch
"colorscheme desert
"syntax on
"set title
"set ruler
"set showmatch
"set autoindent
"set tabstop=4
"set shiftwidth=4
"set expandtab

" zen coding settings
"imap <nul> <c-y>,
"let g:user_zen_expandaddr_key='<Nul>'


let $PYTHON_DLL = "/Users/shichiku_yuki/.pythonbrew/build/Python-2.6.8/libpython2.6.dylib"
