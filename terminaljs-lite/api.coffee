config          = require './config'
Kite            = require 'kite'

{FakeTerminal,FakeController} = require './faketerminal'


{Terminal}  = require "./terminal"                               
htmlify     = require "./htmlify"

console.log "my pid is:",process.pid

module.exports = new Kite 'terminaljs'
  
  _connect:-> console.log "connect:",arguments
  
  _disconnect:(options)-> console.log "kill received from opt#{options.username}" # controller.kill requesterId
  
  create  : (options,callback)  =>
    console.log "creating new terminal for #{options.username}"
    {username,rows,cols,callbacks} = options
    # obj =
    #  create : -> console.log "create"
    #  test : (callback) => callback Date.now()
    # return callback "",obj
     

    unless username and rows and cols and callbacks
      console.log "invalid options, usage : create({rows,cols,type,callbacks},callback)" 
    else
      # create a fake one, use this to detect network lags, errors etc.
      # callback null, FakeController.createTerminal options
      
      #create a real one.
      terminal = new Terminal "/bin/bash",rows,cols
      nr = 0
      terminal.on "data",(screen)->
        callbacks.data screen,nr++
      callback null,
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


  close  : (options,callback)  =>
    controller.kill options.id
    callback? null
