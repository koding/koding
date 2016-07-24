if exists("b:current_syntax")
  finish
endif

if !exists("main_syntax")
  let main_syntax = 'html'
endif

runtime! syntax/gotpl.vim
runtime! syntax/html.vim
unlet b:current_syntax


let b:current_syntax = "gotplhtml"
