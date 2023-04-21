if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

:colorscheme default

set modeline
set modelines=2
set incsearch
set ai
syntax on
set showmode
set smartcase
set t_Co=256
set autowrite

set viminfo='10,\"100,:20,%,n~/.viminfo
set wildignore=*.o,*.obj,*.bak,*.exe
set browsedir=buffer
"set nohlsearch
set splitbelow
set splitright
":hi Search ctermbg=LightYellow

set nocompatible
set nonumber
"set mouse=a
set history=100
"set clipboard=unnamedplus

"set completeopt=menuone,menu,longest

set wildignore+=*\\tmp\\*,*.swp,*.swo,*.zip,.git,.cabal-sandbox
set wildmode=longest,list,full
set wildmenu

set t_Co=256

set cmdheight=1
"nmap = :nohl<CR>

set binary
set noendofline
set cm=blowfish2
set nowrap
set nowrapscan

set listchars=tab:▸▸
"nmap ,n :set nolist<CR>
"nmap ,l :set list<CR>

set softtabstop=2
set shiftwidth=2
set tabstop=2
set expandtab

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
nmap \ :tn<CR>

autocmd BufNewFile,BufRead *.html set syntax=javascript

