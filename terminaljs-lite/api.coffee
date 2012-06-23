class Faker
  
  create : (options) ->
    console.log "faking write"    
    return faker =
      write : (str)->
        console.log "faking write"
        options.data str
      setScreenSize : ->
        console.log "faking write"
    
    #fake screen.on "data"
    i=0
    setInterval ->
      options.data Date.now()+"\n",i++
    ,1000
  
  kill : ->
    console.log "faking kill"    



config      = require './config'
Kite        = require 'kite'
controller  = new Faker #(require("terminaljs-lite").TerminalController)
log4js      = require 'log4js'
log         = log4js.getLogger "[#{config.name}]"


# log4js.addAppender log4js.fileAppender(config.logFile), config.name if config.logFile?



module.exports = new Kite 'terminaljs'
  
  _connect:-> console.log "connect:",arguments
  
  _disconnect:({requesterId})-> controller.kill requesterId
  
  create  : (options,callback)  =>
    log.info "creating new terminal for #{options.username}"
    {username,rows,cols,callbacks} = options
    # obj =
    #  create : -> console.log "create"
    #  test : (callback) => callback Date.now()
    # return callback "",obj
     
    try
      if username and rows and cols and callbacks
        # throw "invalid options, usage : create({rows,cols,type,callbacks},callback)" 
        controller.kill options.id
        options.cmd = "su -l #{username}\n"
        options.id = username
        # console.log "im here with options:",options
        result = controller.create options
        callback? null, 
          id                 : result.id
          type               : "anyterm.js"
          isNew              : yes
          totalSessions      : 1
          write              : (cmd) ->  result.terminal.write cmd
          resize             : (rows, cols) -> result.terminal.setScreenSize rows, cols
          close              : ()->
            try
              controller.kill result.id
              delete result
            catch e
              log.debug "failed to close session : #{e}"
          kill               : ()->
            try
              controller.kill result.id
              delete result
            catch e
              log.debug "failed to kill terminal #{e}"
          closeOtherSessions : ()->
            #just to be compatible with other terminaljs
          ping:()->
          test:(callback)->
            console.log "i'm pinged,returning a callback now"
            callback Date.now()
      else
        console.log "invalid options, usage : create({rows,cols,type,callbacks},callback)",options,callback
    catch e
      console.log "failed to create terminal : #{e}"
      callback? e

  close  : (options,callback)  =>
    controller.kill options.id
    callback? null
