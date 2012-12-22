fs                = require 'fs'
sys               = require 'util'
{spawn, exec}     = require 'child_process'
{EventEmitter}    = require 'events'
log =
  info  : console.log
  error : console.log
  debug : console.log
  warn  : console.log
util              = require 'util'
_                 = require './node_modules/underscore'


class ProcessMonitor extends EventEmitter
  
  constructor:(options)->
    @options = options ? {run:""}
    @nodeServer = {}
    @attachListeners()
    @flags =
      restart : no
      restartInterval : 1000
    @startProcess() if @options?.start?
    
  attachListeners:->
    @on "processDidExit",(code)=>
      if @flags.restart
        process.nextTick =>
          @startProcess() 
          @flags.restart = no

  setRunCommand:(run)->
    @options.run = run
  
  monitorResourceUsage:(interval=5000)->
    # dont use this.
    setInterval ()=>
      log.info util.inspect @nodeServer.memoryUsage()
    ,interval
    
  restartProcess : (options)->
    @flags.restart = yes
    @stopProcess()

  pickUpTheErrorLine:(err)->
    try
      a = err.split("\n")
      for i,k in a
        if i.match("at ") and i.match(":")
          erroneousLine = i
          break
          
      b = erroneousLine.split(":")
      path    = if b[0].match(/\(/) then (b[0].split "(")[1] else (b[0].replace(/^\s*|\s*$/g, '').split " ")[1]
      lineNr  = b[1]*1
      column  = if b[2].match(/\)/) then (b[2].split ")")[0]*1 else b[2]*1
    
      file    = (fs.readFileSync path,'utf-8').split("\n")

      if /.coffee$/.test path
        cs    = require 'coffee-script'
        file  = cs.compile file, bare: yes

      pointer = ""
      for i in [0..column-1]
        pointer += " "
      pointer += "^"
      a.splice k,0,file[lineNr-5]
      a.splice k+1,0,file[lineNr-4]
      a.splice k+2,0,file[lineNr-3]
      a.splice k+3,0,file[lineNr-2]
      a.splice k+4,0,file[lineNr-1]
      a.splice k+5,0,pointer
      a.splice k+6,0,file[lineNr]
      a.splice k+7,0,file[lineNr+1]
      a.splice k+8,0,file[lineNr+2]      
      r = a#[0..k+9]

      return r.join("\n")
    catch e
      log.warn "for this error,pickUpTheErrorLine() failed to show you the line @ProcessMonitor, you're on your own."
      return err
  
  hideAnnoyingEventEmitterLog:(data)->
    str = "(ignored annoying eventemitter 11 listeners added shit.)"
    if data.match "EventEmitter memory leak detected." then return str
    if data.match "at EventEmitter.<anonymous>" then return str
    return data
  startProcess :->
    
  stopProcess : ()->
    log.info "Stopping the process... #{@nodeServer.pid}"
    exec "kill -9 #{@nodeServer.pid}",(err,stdout,stderr)=>

module.exports = ProcessMonitor

# test:
# a = new ProcessMonitor run:["coffee",["./ServerTest.coffee"]],start:yes
# setInterval (()->a.restartProcess()),4000
