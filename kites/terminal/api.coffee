config          = require './config'
Kite            = require 'kite'
_               = require 'underscore'

{Terminal}  = require("terminaljs").Terminal
# {htmlify}   = require("terminaljs")

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
      # terminal.lastScreen = ""
      nr = 0
      terminal.on "data", (screen)-> 
        #scr = ( screen.row(line) for line in [0..screen.rows]).join "\n"
        #scr = htmlify.convert screen
        patch = terminal.getHtml()
        # console.log(patch)
        # patch = dmp.patch_make terminal.lastScreen, scr        
        # terminal.lastScreen = scr
        callbacks.data patch, nr++

      _lastMessageProcessed = 0
      _orderedMessages = {}

      consumeMessages = ->

        while _orderedMessages[_lastMessageProcessed]
          terminal.write _orderedMessages[_lastMessageProcessed].cmd
          delete _orderedMessages[_lastMessageProcessed]
          _lastMessageProcessed++
          # console.log _orderedMessages,_lastMessageProcessed

        ###
        for key,o of _orderedMessages
          do (key)->
            console.log {key,_lastMessageProcessed}
            #give 1 sec for missing messages to arrive, else skip.
            if key
              setTimeout ->
                # console.log "skipping ahead.. missing keys didn't arrive in one sec.",{key,_lastMessageProcessed}

                #
                if _lastMessageProcessed < key
                  _lastMessageProcessed = key
                  delete _orderedMessages[k] for k,oo in _orderedMessages when k < key

                # consumeMessages()
              ,1000
          break
          ###
      clientObject =
        id                 : terminal.id
        type               : "anyterm.js"
        isNew              : yes
        totalSessions      : 1
        write              : (data) ->
          # _orderedMessages[d[0]] = group:d[1],time:d[2],cmd:d[3] for d in data
          # _orderedMessages = _.sortBy _orderedMessages,((e)-> return e[0])
          # console.log {data}

          terminal.write d[3] for d in data
          # consumeMessages()

          # process = (msg)->
          #   baseTime = msg[0][1]
          #   sendKeystroke = (bufferedKeystroke)->
          #     setTimeout (-> terminal.write bufferedKeystroke[0]),bufferedKeystroke[1]-baseTime
          #   sendKeystroke(cmd) for cmd in msg
          #
          #
          # _orderedMessages[messageNum] = data
          # # console.log _orderedMessages,_lastMessageProcessed
          # do (messageNum) ->
          #   if messageNum is _lastMessageProcessed+1
          #     console.log "correct.."
          #     for msg in _orderedMessages[messageNum.._orderedMessages.length-1]
          #       do (msg,messageNum)->
          #         if Array.isArray(msg)
          #           process msg
          #           _lastMessageProcessed++
          #           if _lastMessageProcessed is _orderedMessages.length-1
          #             console.log "finished processing the queue."
          #         else
          #           unless _lastMessageProcessed is _orderedMessages.length-1
          #             console.log "seems like a msg didn't arrive..will wait..",_lastMessageProcessed,_orderedMessages.length
          #           else
          #             console.log "finished processing the queue (on 'else' why?)."
          #   else
          #     console.log "waiting for the missing screen:",messageNum
          #     setTimeout ->
          #       unless Array.isArray(_orderedMessages[messageNum])
          #         console.log ["[skipped a beat]",Date.now()],messageNum+1
          #         clientObject.write ["[skipped a beat]",Date.now()],messageNum+1
          #       else
          #         console.log "we waited for screenNr:#{messageNum} and it did arrive before 1sec."
          #     ,1000

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
