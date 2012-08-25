class FSWatcher extends jraphical.Module
  {secure} = require 'bongo'
  
  log4js      = require "log4js"
  logger      = log4js.getLogger("[FSWatcher]")
  
  log         = logger.info.bind logger
  warn        = logger.warn.bind logger
  
  @share()
  
  @_watchers: {}

  @set
    sharedMethods: 
      static : ['watch', 'unwatch', 'onChange']
      
  getWatcher = (connection) ->
    if FSWatcher[connection.clientId]
      FSWatcher[connection.clientId]
    else
      FSWatcher[connection.clientId] = new Watcher connection
      
  @watch: secure (client, {dir}, callback) ->
    log 'asked to watch for', dir
    getWatcher(client.connection).watch dir
    
  @unwatch: secure (client, {dir}, callback) ->
    log 'unwatch called, but I dont know api for unsubscribing'
    
  @onChange: secure (client, callback) ->
    log 'on change', callback
    getWatcher(client.connection).on 'change', callback
      
      
class Watcher extends EventEmitter
  log4js      = require "log4js"
  logger      = log4js.getLogger("[Watcher]")
  
  log         = logger.info.bind logger
  warn        = logger.warn.bind logger
  
  constructor: (@connection) ->
    @_subscriptions = {}
    
    # @api = bongo.kites.fsWatcherKitesTest.api
    
    kiteController.tell kiteName:"fsWatcher",method:"on",withArgs:'start', (a, b, c) ->
      log 'start', a, b, c
      
    kiteController.tell kiteName:"fsWatcher",method:"on",withArgs:'warn', (a, b, c) ->
      log 'warn', a, b, c
      
    # @api.on 'fschange', (event) =>
    #   @emit 'change', event
      
  watch: (dir) ->
    newId = hat()
    @_subscriptions[dir] = newId
    
    kiteController.tell kiteName:"fsWatcher",method:"watch",withArgs:{dir, eventID: newId}
    kiteController.tell kiteName:"fsWatcher",method:"on", withArgs:newId, (event) =>
      @emit 'change', event
      
      
      
      
      
      
      
      
  