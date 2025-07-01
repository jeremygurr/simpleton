" if has("autocmd")
"   au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
" endif

:colorscheme torte

let g:is_bash=1

set ruler
set modeline
set modelines=2
set incsearch
set ai
set sc
syntax on
set showmode
set smartcase
set t_Co=256
set autowrite
set viminfo='10,\"100,:20,%,n~/.viminfo
set wildignore=*.o,*.obj,*.bak,*.exe
set browsedir=buffer
set splitbelow
set splitright
set nocompatible
set history=100
set wildignore+=*\\tmp\\*,*.swp,*.swo,*.zip,.git,.cabal-sandbox
set wildmode=longest,list,full
set wildmenu
set wrap
set nowrapscan
set softtabstop=2
set shiftwidth=2
set tabstop=2
set expandtab
set syntax=bash

nmap du :diffupdate<CR>
set diffexpr=MyDiff()
  function MyDiff()
    silent execute "!diff -dw " . v:fname_in . " " . v:fname_new .
         \  " > " . v:fname_out
  endfunction

set listchars=eol:$,tab:>-,trail:~,extends:>,precedes:<
nmap <CR> z<CR>
set cot=

nmap gr :silent lgrep --exclude tags --exclude-dir .git -RI '\<<C-r><C-W>\>' .<CR><C-l>
nmap , :lne<CR>
nmap g, :lpr<CR>
nmap \ :tn<CR>
nmap g\ :tp<CR>
nmap gs j:q<CR>:split<CR>

autocmd BufNewFile,BufRead *.html set syntax=javascript

