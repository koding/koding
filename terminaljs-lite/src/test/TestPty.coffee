{pty, htmlify, DiffScriptFactory} = require "anyterm.js"
terminal = new pty "/bin/bash", 10, 10
diffFactory = new DiffScriptFactory
terminal.on "data",(data)->
  screen = htmlify.convert terminal.getScreen()
  diff   = diffFactory.createScript screen
  console.log "data : #{diff}"

terminal.write "ls -la\n"
