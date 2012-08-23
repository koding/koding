config          = require './config'
Kite            = require 'kite-amqp'
_               = require 'underscore'
{exec}          = require 'child_process'

{Terminal}  = require("terminaljs").Terminal


console.log "my pid is:",process.pid

module.exports = new Kite 'terminaljs'

  _connect:-> 
    console.log "_connect is called with:",arguments

  _disconnect:(options)-> 
    console.log "_disconnect is received with",arguments
    {username,requesterId} = options
    if requesterId then username = requesterId
    
    if requesterId is "undefined" or username is "undefined" then console.log "_disconnect : ignoring 'undefined'"

    exec "killall -9 -u #{username}",(err,stdout,stderr)->
          console.log "[_disconnect][killing everything that belongs to #{username}]",arguments
    
  create  : (options,callback)  =>
    console.log "creating new terminal for #{options.username}"
    {username,rows,cols,callbacks} = options

    unless username isnt "undefined" and username and rows and cols and callbacks      
      console.log "invalid options, usage : create({rows,cols,type,callbacks},callback)" 
    else
      # create a fake one, use this to detect network lags, errors etc.
      # return callback null, FakeController.createTerminal options

      #create a real one.      # 
      terminal = new Terminal "su -l #{username}",rows,cols
            
      # terminal = new Terminal "bash echo fuck you",rows,cols

      nr = 0
      terminal.on "data", (screen)-> 

        patch = terminal.getHtml()
        callbacks.data patch, nr++

      clientObject =
        id                 : terminal.id
        type               : "anyterm.js"
        isNew              : yes
        totalSessions      : 1
        write              : (data) ->        
          terminal.write d[3] for d in data

        resize             : (rows, cols) -> terminal.setScreenSize rows, cols
        close              : ()->
          console.log "close is called"
          terminal.kill terminal.id
          #delete terminal
        kill               : ()->
          console.log "kill is called"
          terminal.kill terminal.id
          #delete terminal
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
