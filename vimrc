" Setting for dein
" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif

" 設定開始
if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " プラグインリストを収めた TOML ファイル
  " 予め TOML ファイル（後述）を用意しておく
  let g:rc_dir    = expand('~/.vim/rc')
  let s:toml      = g:rc_dir . '/dein.toml'
"  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  " TOML を読み込み、キャッシュしておく
  call dein#load_toml(s:toml,      {'lazy': 0})
"  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  " 設定終了
  call dein#end()
  call dein#save_state()
endif

" もし、未インストールものものがあったらインストール
if dein#check_install()
  call dein#install()
endif


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
set lazyredraw
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

  au BufNewFile,BufRead *.ect set filetype=html
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

" solarized
"let g:solarized_termcolors=256
"let g:solarized_termtrans=0
"let g:solarized_degrade=0
"let g:solarized_bold=1
"let g:solarized_underline=1
"let g:solarized_italic=1
"let g:solarized_contrast='normal'
"let g:solarized_visibility='normal'
let g:hybrid_use_Xresources = 1

" molokai
let g:molokai_original = 1
let g:rehash256 = 1

syntax enable
set t_Co=256
set background=dark
"colorscheme mango
"colorscheme proteus
"colorscheme solarized
"colorscheme distinguished
"colorscheme molokai
colorscheme hybrid

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

au BufNewFile,BufRead *.tag set filetype=javascript

" ====================
" Syntastic
" ====================
let g:syntastic_enable_signs=1
"let g:syntastic_auto_jump=1
"let g:syntastic_check_on_open=1w
let g:syntastic_check_on_wq=0
let g:syntastic_loc_list_height = 6
let g:syntastic_javascript_jscs_args = '--config $HOME/.jscsrc'

"let g:syntastic_javascript_jshint_conf = '$HOME/.jshintrc'

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 0 " show log 
let g:syntastic_auto_loc_list = 1 " show log 
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0 " check when write file if mode active
let g:syntastic_mode_map = { "mode": "passive",
      \ 'active_filetypes': ['javascript', 'json'],
      \ 'passive_filetypes': ['html'] }
let g:syntastic_javascript_checkers = ['eslint']
map <C-l> :SyntasticCheck<cr>

map <c-h> :Esformatter<cr>
autocmd FileType javascript noremap <buffer>  <c-h> :Esformatter<cr>

" ====================
" ctrlp
" ====================
let g:ctrlp_use_migemo = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_mruf_max            = 500
let g:ctrlp_custom_ignore = 'DS_Store\|git\|hg\|svn\|optimized\|compiled\|node_modules\|bower_components'
" let g:ctrlp_open_new_file       = 1


" ====================
" vim-indent-guides
" ====================
let g:indent_guides_auto_colors=0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd   ctermbg=240
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven  ctermbg=250
let g:indent_guides_enable_on_vim_startup=2
let g:indent_guides_guide_size=1

" Jq for vim
command! -nargs=? Jq call s:Jq(<f-args>)
function! s:Jq(...)
    if 0 == a:0
        let l:arg = "."
    else
        let l:arg = a:1
    endif
    execute "%! jq \"" . l:arg . "\""
endfunction


" ====================
" clip board
" ====================
if has('nvim')
  set clipboard+=unnamedplus
  function! ClipboardYank()
    call system('pbcopy', @@)
  endfunction
  function! ClipboardPaste()
    let @@ = system('pbpaste')
  endfunction
  vnoremap <silent> y y:call ClipboardYank()<cr>
  vnoremap <silent> d d:call ClipboardYank()<cr>
  nnoremap <silent> p :call ClipboardPaste()<cr>p
else
  set clipboard=unnamed,autoselect
endif

" ====================
" file encoding
" ====================
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8


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


"let $PYTHON_DLL = "/Users/shichiku_yuki/.pythonbrew/build/Python-2.6.8/libpython2.6.dylib"

" NERDTree
nnoremap <silent><C-a> :NERDTree<CR>
