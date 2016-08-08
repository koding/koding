"============================================================================
"File:        gonyet.vim
"Description: Perform static analysis of Go code with the go-nyet tool
"Maintainer:  Barak Michener <me@barakmich.com>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

if exists("g:loaded_syntastic_go_gonyet_checker")
    finish
endif
let g:loaded_syntastic_go_gonyet_checker = 1

let s:save_cpo = &cpo
set cpo&vim

function! SyntaxCheckers_go_gonyet_IsAvailable() dict
    return executable('go-nyet')
endfunction

function! SyntaxCheckers_go_gonyet_GetLocList() dict
    let makeprg = 'go-nyet ' . expand('%:p')
    let errorformat = '%f:%l:%c:%m' 

    " The go compiler needs to either be run with an import path as an
    " argument or directly from the package directory. Since figuring out
    " the proper import path is fickle, just cwd to the package.

    let errors = SyntasticMake({
        \ 'makeprg': makeprg,
        \ 'errorformat': errorformat,
        \ 'cwd': expand('%:p:h'),
        \ 'defaults': {'type': 'w'} })

    return errors
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'go',
    \ 'name': 'gonyet'})

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set et sts=4 sw=4:
