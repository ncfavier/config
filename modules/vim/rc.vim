" Defaults

silent! source $VIMRUNTIME/defaults.vim

" Plugins

let NERDTreeMinimalUI = 1
let NERDTreeRespectWildIgnore = 1

let NERDSpaceDelims = 1
let NERDDefaultAlign = 'left'
let NERDCommentEmptyLines = 1
let NERDToggleCheckAllLines = 1

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

let vim_markdown_folding_disabled = 1
let vim_markdown_math = 1
let vim_markdown_frontmatter = 1
let vim_markdown_new_list_item_indent = 0

let g:haskell_enable_quantification = 1
let g:haskell_enable_recursivedo = 1
let g:haskell_enable_arrowsyntax = 1
let g:haskell_enable_pattern_synonyms = 1
let g:haskell_enable_typeroles = 1

" Options

set autoindent
set autoread
set breakindent
set clipboard=unnamedplus,exclude:cons\|linux
set expandtab
set exrc
set formatoptions-=tro
set hidden
set hlsearch
set ignorecase
set incsearch
set laststatus=1
set modeline
set mouse=a
set nonumber
set path=**
set secure
set shiftround
set shiftwidth=0
set smartindent
set softtabstop=4
set splitbelow
set splitright
set suffixes+=.hi,.dyn_hi,.dyn_o,.cmi,.cmo,.bcf,.fdb_latexmk,.fls,.pdf,.xdv,.aux,.blg,.bbl,.run.xml,.lock
set tabstop=4
set title
set ttimeoutlen=10
set ttymouse=xterm2
set whichwrap=b,s,<,>,[,]
set wildignore+=**/dist-newstyle/**
set wildignorecase

set visualbell
set t_vb=

if &term =~ '^rxvt-unicode'
    set ttymouse=urxvt
endif

if &term == 'alacritty'
    execute "set <xUp>=\e[1;*A"
    execute "set <xDown>=\e[1;*B"
    execute "set <xRight>=\e[1;*C"
    execute "set <xLeft>=\e[1;*D"
endif

" cursor shapes
let &t_SI = "\e[5 q"
let &t_EI = "\e[0 q"
let &t_SR = "\e[3 q"

colorscheme pablo

" Mappings

let mapleader = ','

noremap           <Home>           ^
nnoremap <silent> <Return>         :noh<Bar>redraw!<Bar>echo<Return>
imap              <Home>           <C-o><Home>
inoremap <expr>   <Tab>            (col('.') == 1 \|\| getline('.')[:col('.')-2] =~ '^\s*$') ? "\<Tab>" : "\<C-n>"
inoremap          <C-f>            <C-x><C-f>
vmap              <Tab>            >
vmap              <S-Tab>          <
vnoremap          >                >gv
vnoremap          <                <gv
vnoremap          =                =gv
nnoremap          <Tab>            >>
nnoremap          <S-Tab>          <<
nnoremap <silent> <C-j>            mz:move +1<Return>==`z
nnoremap <silent> <C-k>            mz:move -2<Return>==`z
vnoremap <silent> <C-j>            :move '>+1<Return>gv=gv
vnoremap <silent> <C-k>            :move '<-2<Return>gv=gv
nnoremap          <C-a>            ggVG
nnoremap          +                <C-a>
nnoremap          -                <C-x>
nnoremap          p                ]p
nnoremap          P                ]P
vnoremap          //               y/\V<C-r>=escape(@",'/\')<Return><Return>
vnoremap          ??               y?\V<C-r>=escape(@",'?\')<Return><Return>
noremap  <silent> <C-l>            :set number!<Return>
noremap  <silent> <C-c>            :call nerdcommenter#Comment(0, 'toggle')<Return>
noremap  <silent> <C-n>            :NERDTreeToggle<Return>
noremap           <C-p>            :find<Space>
cnoremap          <C-p>            <C-u>vert sfind<Space>
noremap           <C-Left>         <C-w>h
noremap           <C-Right>        <C-w>l
noremap           <C-Down>         <C-w>j
noremap           <C-Up>           <C-w>k
noremap  <silent> <C-s>            :update<Return>
noremap  <silent> <Leader><Leader> :map <Leader><Return>
noremap           <Leader>mm       :!make<Return>
noremap           <Leader>mi       :!make install<Return>
noremap           <Leader>mc       :!make clean<Return>
noremap           <Leader>m<Space> :!make<Space>
noremap           <Leader>i        :AddImport<Bar>SortImports<Return>
nnoremap          <Leader>r        :%s///g<Bar>''<Left><Left><Left><Left><Left>
nnoremap          <Leader>n        :%s///gn<Return>
noremap  <silent> <Leader>s        :sort<Return>
noremap  <silent> <Leader>u        :write !upload<Return>
noremap  <silent> <Leader>x        :execute '!chmod +x -- '.shellescape(@%)<Return>
noremap  <silent> <Leader>d        :execute 'write !diff - '.shellescape(@%)<Return>

" Autocommands

" quit if NERDTree is the last buffer open
autocmd BufEnter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | quit | endif

" set filetype to bash when editing bash dotfiles
autocmd BufNewFile,BufRead ~/.dots/bash/* call dist#ft#SetFileTypeSH("bash")

" delete trailing whitespace on write
autocmd BufWritePre * %s/\s\+$//e

" auto-chmod files with a shebang
autocmd BufWritePost * if getline(1) =~ '^#!' && !executable(expand('%:p')) | silent execute '!chmod +x -- '.shellescape(@%) | endif

" source vimrc after writing it
autocmd BufWritePost $MYVIMRC source $MYVIMRC

" upload to ix.io on write
autocmd BufWriteCmd http://ix.io/* write !curl -F 'f:1=<-' ix.io | tee >(clip)

" balance windows when the terminal is resized
autocmd VimResized * wincmd =

" indent haskell with 2 spaces
autocmd Filetype haskell setlocal tabstop=2 softtabstop=2

" Commands

command! Reload source $MYVIMRC
command! ToggleTerm call ToggleTerm()

" Terminal

if v:version >= 800
    noremap  <silent> <C-t> :ToggleTerm<Return>
    tnoremap <silent> <C-t> <C-w>:ToggleTerm<Return>
    tnoremap <silent> <Esc><Esc> <C-\><C-n>

    function! ToggleTerm()
        if &buftype == 'terminal'
            close
            return
        endif

        let terminal_windows = filter(getwininfo(), 'v:val.terminal')
        if !empty(terminal_windows)
            execute terminal_windows[0].winnr.'wincmd w'
            return
        endif

        let terminal_buffers = filter(getbufinfo(), 'getbufvar(v:val.bufnr, ''&buftype'') == ''terminal''')
        if !empty(terminal_buffers)
            execute 'botright sbuffer' terminal_buffers[0].bufnr
            return
        endif

        botright terminal ++close ++kill=term ++norestore
    endfunction
endif

" Move temporary files to a secure location to protect against CVE-2017-1000382
if exists('$XDG_CACHE_HOME')
  let &g:directory=$XDG_CACHE_HOME
else
  let &g:directory=$HOME . '/.cache'
endif
let &g:undodir=&g:directory . '/vim/undo//'
let &g:backupdir=&g:directory . '/vim/backup//'
let &g:directory.='/vim/swap//'
" Create directories if they doesn't exist
if ! isdirectory(expand(&g:directory))
  silent! call mkdir(expand(&g:directory), 'p', 0700)
endif
if ! isdirectory(expand(&g:backupdir))
  silent! call mkdir(expand(&g:backupdir), 'p', 0700)
endif
if ! isdirectory(expand(&g:undodir))
  silent! call mkdir(expand(&g:undodir), 'p', 0700)
endif

" Create inexistent directories on save
augroup vimrc-auto-mkdir
  autocmd!
  autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
  function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir)
          \   && (a:force
          \       || input(a:dir . " does not exist. Create? [y/N] ") =~? '^y\%[es]$')
      call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
  endfunction
augroup END
