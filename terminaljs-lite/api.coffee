config          = require './config'
Kite            = require 'kite'
_               = require 'underscore'
dmp             = new (new require('diff_match_patch')).diff_match_patch() 
{FakeTerminal,FakeController} = require './faketerminal'


{Terminal}  = require("terminaljs").Terminal
{htmlify}   = require("terminaljs")

console.log "my pid is:",process.pid

module.exports = new Kite 'terminaljs'

  _connect:-> console.log "connect:",arguments

  _disconnect:(options)-> console.log "kill received from opt#{options.username}" # controller.kill requesterId

  create  : (options,callback)  =>
    console.log "creating new terminal for #{options.username}"
    {username,rows,cols,callbacks} = options
     
    unless username and rows and cols and callbacks
      console.log "invalid options, usage : create({rows,cols,type,callbacks},callback)" 
    else
      # create a fake one, use this to detect network lags, errors etc.
      # return callback null, FakeController.createTerminal options

      #create a real one.
      terminal = new Terminal "su -l #{username}",rows,cols
      terminal.lastScreen = ""
      nr = 0
      terminal.on "data",_.throttle (screen)-> 
        # scr = ( screen.row(line) for line in [0..screen.rows]).join "\n"
        scr = htmlify.convert screen
        patch = dmp.patch_make terminal.lastScreen, scr        
        terminal.lastScreen = scr
        callbacks.data patch, nr++
      ,10

      clientObject =
        id                 : terminal.id
        type               : "anyterm.js"
        isNew              : yes
        totalSessions      : 1
        write              : (cmd) ->  terminal.write cmd
        resize             : (rows, cols) -> terminal.setScreenSize rows, cols
        close              : ()->
          console.log "close is called"
          terminal.kill terminal.id
          delete terminal
        kill               : ()->
          console.log "kill is called"
          terminal.kill terminal.id
          delete terminal
        closeOtherSessions : ()->
          #just to be compatible with other terminaljs
        ping:()->
        test:(callback)->
          console.log e = "i'm really pinged,returning a callback now"
          callback e, Date.now()

    callback null, clientObject

  close  : (options,callback)  =>
    controller.kill options.id
    callback? null
