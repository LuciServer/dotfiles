set nocompatible
syntax enable
set encoding=utf-8
set fileencoding=utf-8

" UI
set number
set relativenumber
set ruler
set cursorline
set wildmenu
set mouse=a
set nowrap
set sidescroll=1
set sidescrolloff=5

" Indentation
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
set smartindent
set smarttab

" Whitespace
set list
set listchars=tab:»·,trail:·
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Files
set hidden
set autoread
set nobackup
set nowritebackup

" Performance
set lazyredraw
set ttyfast

" Splits
set splitright
set splitbelow

" Clipboard
set clipboard=unnamedplus

" Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Leader shortcuts
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>/ :Commentary<CR>

" Plugins
call plug#begin('~/.vim/plugged')

Plug 'preservim/nerdtree'
Plug 'itchyny/lightline.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'dense-analysis/ale'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" NERDTree
nnoremap <C-n> :NERDTreeToggle<CR>

" Status line
set laststatus=2
let g:lightline = { 'colorscheme': 'wombat' }

" ALE
let g:ale_fix_on_save = 1
let g:ale_linters = {
\ 'yaml': ['yamllint'],
\ 'javascript': ['eslint'],
\ 'python': ['flake8']
\}

let g:ale_fixers = {
\ '*': ['remove_trailing_lines', 'trim_whitespace'],
\ 'javascript': ['prettier'],
\ 'yaml': ['prettier'],
\}

" Markdown preview
let g:mkdp_auto_start = 1

" CoC completion
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : coc#refresh()
inoremap <expr> <CR> pumvisible() ? coc#_select_confirm() : "\<CR>"

" YAML formatting
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
