{connectKite} = require 'bongo-client'
KiteServer    = require 'kiteserver'
fs            = require 'fs'
log4js        = require 'log4js'
log           = log4js.addAppender log4js.fileAppender("/var/log/node/FsWatcherApi.log"), "[fsWatcherApi-client]"
log           = log4js.getLogger('[fsWatcherApi-client]')
util          = require 'util'

cleanupInterval   = 20 #sec
startCleanupAfter = 200 # events
cleanupLock       = false

Kite            = null
eventIds        = [] # array for all event IDs

Array::findAndRemove = (dir)->
  __tmpArray = []
  for obj in @
    if obj.dir isnt dir
      __tmpArray.push obj
    else
      removedElement = obj
  return newArray:__tmpArray,removedElement:removedElement


class FsWatcherKites


  startCleanuper : ()->
    if not cleanupLock
      cleanupLock = true
      log.info "[CLEANUPER] clenauper started with interval #{cleanupInterval} sec"
      setInterval ()=>
        if eventIds.length > startCleanupAfter
          removedElement = eventIds.shift()
          log.info "[CLEANUPER] removed event is: "
          log.info removedElement
          fsWatcher.removeWatcher dir:removedElement.dir,(result)->
            fsWatcher.removeAllListeners removedElement.eventID
            Kite.emit "cleanedup",eventID:removedElement.eventID,dir:removedElement.dir
            log.info "[OK] sucsessfully removed watch for dir #{removedElement.dir} with event ID #{removedElement.eventID}"
        else
          log.info "[CLEANUPER] only #{eventIds.length} events in event array, nothing to remove"
      ,cleanupInterval*1000
    else
      #log.warn "[WARN] cleanuper already started"

  watch : (options)-> # creating method for kite (creating kite)

    @startCleanuper()


    fsWatcher.watchForDir options,(error,warning,result)=>
      if warning?
        log.warn warning
        try
          log.debug "removing #{options.dir}"
          result = eventIds.findAndRemove options.dir
          eventIds = result.newArray
          eventIds.push eventID:options.eventID,dir:options.dir
          fsWatcher.removeAllListeners result.removedElement.eventID # cleanup old related to eventID listeners
          log.info "[OK] an old FS listener in event #{result.removedElement.eventID} for dir #{options.dir} has been removed, new with ID #{options.eventID} added"
        catch error
          log.error "[ERR] can't remove an old FS listener in event #{result.removedElement.eventID} for dir #{options.dir} : #{error}"
      else if error?
        log.error error
      else
        eventIds.push eventID:options.eventID,dir:options.dir



    fsWatcher.addListener options.eventID,(msg)->
      Kite.emit options.eventID,msg


  removeWatch : (options,callback)->

    fsWatcher.removeWatcher options,(result)->
      fsWatcher.removeAllListeners options.eventID
      res = eventIds.findAndRemove options.dir
      eventIds = res.newArray
      log.info "[OK] sucsessfully removed watch for dir #{res.removedElement.dir} with event ID #{res.removedElement.eventID}"
      callback? result #true/false


watcher = new FsWatcherKites



############################### KITES ########################################################
fsWatcherKites =
  watch : (options)-> watcher.watch options
  removeWatch : (options,callback)-> watcher.removeWatch options, (result)-> callback? result
############################### END OF KITES #################################################




config =
  name     : "fsWatcher"
  portRange     : [4501,4600]
  kiteApi       : fsWatcherKites
  pidFile       :
    path      :  '/var/run/node/FsWatcherApi.pid'
    required  : no
  kiteServer    :
    host      : "bs1.beta.system.aws.koding.com"
    # host      : "localhost"
    port      : 4501
    reconnect : 1000

new KiteServer(config).start()
