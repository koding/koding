class FSWatcher extends jraphical.Module
  
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
      
  bongo.on "clientDidDisconnect",(conn)->
    # log "user disconnected kill - "+Terminal.terminals[conn.clientId]+" if user doesn't come back in next 60 seconds."
    log 'dropping watcher'
    #delete FSWatcher[conn.clientId]
    # anytermKite.close Terminal.terminals[conn.clientId],(err,res)->
    #       Terminal.terminals[conn.clientId] = null
    
  @watch: bongo.secure (client, {dir}, callback) ->
    log 'asked to watch for', dir
    getWatcher(client.connection).watch dir
    
  @unwatch: bongo.secure (client, {dir}, callback) ->
    log 'unwatch called, but I dont know api for unsubscribing'
    
  @onChange: bongo.secure (client, callback) ->
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
      
      
      
      
      
      
      
      
  