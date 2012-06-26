{EventEmitter}  = require 'events'
_               = require 'underscore'


class FakeController
  @terminals = []
  @createTerminal=(options)->
    FakeController.terminals[options.username] ?= []
    options.id = FakeController.terminals[options.username].length-1
    options.cmd = "su -l #{options.username}"
    terminal = new FakeTerminal options
    FakeController.terminals[options.username].push 
    return terminal

class FakeTerminal extends EventEmitter

  constructor: (options)->
    console.log "faking new terminal",arguments
    writeToClient = options.callbacks.data
    @id = options.id
    @type = "anyterm.js"
    @isNew = yes
    @totalSessions = options.id
    messageNum = 0    
    screen = ""
    i=0
    @write = (str)=>
      console.log "faking write",arguments[0],messageNum,i++
      # screen += "[#{i}]"+str
      screen += str
      @emit "data",screen
    @setScreenSize = ->
      console.log "faking setScreenSize",arguments              
    @kill = ->
      console.log "faking kill",arguments
   
    @on "data",_.throttle (scr)->
      console.log "sending screen",Date.now()
      writeToClient "[#{messageNum}]"+scr,messageNum++
    ,200
module.exports = {FakeTerminal,FakeController}