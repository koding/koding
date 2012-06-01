{pty, htmlify, DiffScriptFactory} = require "anyterm.js"

class Controller

  constructor:()->
    @cache = {}

  create:(options)->

    ###
      options =
        id: session identifier, it can be any string
        cmd: shell command for pty
        rows: terminal height
        cols: terminal width
        callbacks:
          data: callback used when screen has new content 
          error: callback used when error occurs in terminal session
    ###

    session = {}
    session.id = options.id
    console.log "cmd = #{options.cmd} rows=#{options.rows} cols=#{options.cols}"
    session.terminal    = new pty options.cmd, options.rows, options.cols
    session.diffFactory = new DiffScriptFactory

    for own event,callback of options.callbacks
      if event == 'data'
        session.terminal.on "data",(data)=>
          screen = htmlify.convert session.terminal.getScreen()
          diff   = session.diffFactory.createScript screen
          callback diff
      else
        session.terminal.on event, callback

    @cache[options.id] = session
    
    return session

  kill:(id)->
    session = @cache[id]
    if session? and session.terminal?
      session.terminal.kill()
      delete @cache[id]

module.exports = Controller
