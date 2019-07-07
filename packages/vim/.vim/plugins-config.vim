colorscheme frigid

"
let g:webdevicons_enable_airline_tabline = 0
let g:webdevicons_enable_airline_statusline = 1

let g:javascript_plugin_flow      = 1
let g:javascript_conceal_function = "ƒ"
let g:javascript_conceal_null     = "ø"

" nerdcommenter
let g:NERDSpaceDelims = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
nmap <C-_> <leader>c<Space>
vmap <C-_> <leader>c<Space>

xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" Markdown
let g:markdown_fenced_languages = [ 'python', 'bash=sh', 'js=javascript', 'lua', 'purs=purescript', 'purescript' ]

" JSDoc
let g:jsdoc_input_description = 0
let g:jsdoc_enable_es6 = 1
nmap <silent> <Leader>d <Plug>(jsdoc)

" move
let g:move_key_modifier = 'C'

let g:ale_ignore_2_4_warnings = 1

