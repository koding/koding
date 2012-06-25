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
      
      _lastMessageProcessed = 0
      _orderedMessages = []
      clientObject =
        id                 : terminal.id
        type               : "anyterm.js"
        isNew              : yes
        totalSessions      : 1
        write              : (data,messageNum) ->

          _orderedMessages[messageNum] = data
          # console.log _orderedMessages,_lastMessageProcessed
          do (messageNum) ->
            if messageNum is _lastMessageProcessed+1
              console.log "correct.."
              for msg in _orderedMessages[messageNum.._orderedMessages.length-1]
                do (msg,messageNum)->
                  if Array.isArray(msg)
                    baseTime = data[0][1]
                    (do (d)->(setTimeout (-> terminal.write d[0]),d[1]-baseTime)) for d in msg
                    _lastMessageProcessed++
                    if _lastMessageProcessed is _orderedMessages.length-1
                      console.log "finished processing the queue."
                  else
                    unless _lastMessageProcessed is _orderedMessages.length-1
                      console.log "seems like a msg didn't arrive..will wait..",_lastMessageProcessed,_orderedMessages.length
                    else
                      console.log "finished processing the queue (on 'else' why?)."
            else
              console.log "waiting for the missing screen…"
              setTimeout ->
                unless Array.isArray(_orderedMessages[messageNum])
                  console.log ["[skipped a beat]",Date.now()],messageNum+1
                  clientObject.write ["[skipped a beat]",Date.now()],messageNum+1
                else
                  console.log "we waited for screenNr:#{messageNum} and it did arrive before 5secs."
              ,1000
                  
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
