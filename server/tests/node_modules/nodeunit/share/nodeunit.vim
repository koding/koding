" Vim compiler file
" Compiler: Unit testing for javascript using nodeunit
" Maintainer: lambdalisue <lambdalisue@hashnote.net>
" Last Change: 2011 Sep 06
"
" How to install:
"   copy this vim script into $VIM/compiler/ directory
"   and add the line below to $VIM/ftplugin/javascript.vim (or coffee.vim)
"
"       compiler nodeunit
"
" How to use:
"   Test with ':make' command of vim. See vim plugin called 'vim-makegreen'
"   
if exists("current_compiler")
    finish
endif
let current_compiler = "nodeunit"

if exists(":CompilerSet") != 2 " older Vim always used :setlocal
    command -nargs=* CompilerSet setlocal <args>
endif

" Using folked version nodeunit found at
" http://github.com/lambdalisue/nodeunit.git
CompilerSet makeprg=echo\ $*\ >/dev/null;\ nodeunit\ --reporter\ machineout\ \"%\"
CompilerSet efm=%s:%f:%l:%c:%m
