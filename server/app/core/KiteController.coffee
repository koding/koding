class KiteController extends bongo.Base
  log4js  = require "log4js"
  log     = log4js.getLogger("[KiteController]")
  kites   = {}
  
  @heartbeat = ->
    # setInterval ->
    #   for own id,kite of kites
    #     do (id,kite)->
    #       # log.info "pinging #{kite.name}"
    #       kites[id].heartbeat ?= {}          
    # 
    #       kites[id]?.direct?.api?._ping? {},()->
    #         kites[id].heartbeat.direct = Date.now()
    # 
    #       kites[id]?.viaProxy?.api?._ping? {},()->
    #         kites[id].heartbeat.viaProxy = Date.now()
    # 
    #       setTimeout ->
    #         if kites[id]?.viaProxy?.heartbeat+3000 < Date.now()
    #           unregisterKite connType:"viaProxy",kiteId:id
    #         if kites[id]?.direct?.heartbeat+3000 < Date.now()
    #           unregisterKite connType:"direct",kiteId:id
    #       ,1000
    # ,2000
  @heartbeat()
  
  constructor:(@config)->
    super
    @kites = {}
    

  getKiteByName : (kiteName)->

    @query
      type      : "kiteName"
      kiteName  : kiteName
    ,(err,res)=>
      unless err
        # # log.debug "asked #{kiteName} got ",res
        return res[0]
      else
        # # log.debug "kite query failed at getKite"
        return null
        
  query : (query,callback)->

    #
    # this function is not generalized enough, contains only the stuff we currently need, not more. 
    # but it is easily extendable.
    # generalizing it right now means coming up with a query language, non-insignificant amount of work.
    # 
    unless query.type
      query.type = "kiteNameAndHostname"  if query.kiteName and query.hostname
      query.type = "byKiteId"             if query.kiteId
      query.type = "kiteName"             if query.kiteName and not query.hostname and not query.function
      query.type = "kiteNameAndFunction"  if query.kiteName and query.function
      # # log.debug "query.type is set to:#{query.type}"
      
    # # log.debug "incoming query:",query,"kites:",kites
    
    switch query.type 
      when "byKiteId"
        callback null,[id]
      when "kiteName"
        res = (id for id,kite of kites when kite.name and kite.name.match("/#{query.kiteName}/"))
        # # log.debug 'kiteName query res:',res
        callback null,res

      when "kiteNameAndHostname"        
        res = (id for id,kite of kites when kite.name.match(query.hostname) and kite.name.match("/#{query.kiteName}/"))
        # log.debug "sktimin",res,kites
        callback null,res
      when "kiteNameAndFunction"
        res = []
        i = 0
        nrOfKites = @getNrOfKites()
        Object.keys(@kites).forEach (id)=>
          kite = @kites[id]
          if kite.name.match("/#{query.kiteName}/")
            @runFunctionOnKite
              kiteId  : id
              fn      : query.function
              retVal  : true
              ttl     : 1000
            ,(err)->
              i++
              unless err
                res.push kite

              if i is nrOfKites
                callback null,res              
                
  checkKiteId : (kiteId)->  
    return yes for id,kite of @kites when id is kiteId
    return no
  
  runFunctionOnKite : (options,callback)->
    {kiteId,fn,retVal,ttl} = options
    
    unless @checkKiteId(kiteId) then return callback "invalid kiteId"
    
    fn      or= "ping"
    retVal  or= yes
    ttl     or= 1000
    
    err   = "#{@kites[kiteId].name} timing out. (failed to respond in #{ttl/1000} secs. ping&kill next.)"
    done  = no
    setTimeout ->
      callback err unless done
      log.warn err
      done = yes
    ,ttl
    
    kite.api[query.function] (res)->
      if not done
        if res is query.functionReturnValue
          callback null
        else
          callback no
        done = yes

  getNrOfKites:-> return Object.keys(@kites).length
      
  tell : (options,callback)->
    
    {kiteId,method,withArgs,kiteName} = options
    
    if not kiteId and kiteName
      kiteId = @getKiteByName kiteName
    
    #deprecate this - options.kite is not a valid request.
    if not kiteId and options.kite
      kiteId = @getKiteByName options.kite
      
    
    if kites[kiteId]
      kite = kites[kiteId].direct ? kites[kiteId].viaProxy
      # # log.debug kiteId,kite?.name,kites
      if kite
        if kite.api?[method]
          # log.debug "told kite:#{kite.name} method:#{method}"
          kite.api[method] withArgs,options.callback
          callback null
        else
          err = "kite:#{kite.name} said it has no such function:#{method}"
          log.error err
          options.callback? err
          callback? null
      else
        err = "#{kite} - this kite was here but probably disconnected."
        log.error err
        callback? err        
    else
      err = "kiteName:#{kiteName} kiteId:#{kiteId} does not exist or disconnected."
      # log.debug arguments
      log.error err
      callback? err
      
  
  isAllowedToConnect:(incomingKite)->
    kiteName = incomingKite.bongo_.name
    for key,kite of @config.kites
      return key if kiteName is kite.name
    log.warn "this kite is not allowed to connect: #{kiteName}"
    return no
  
  
  @registerKite = ({connType,kite})->
    # kfmjsNameOfTheKite = @isAllowedToConnect kite
    # if kfmjsNameOfTheKite
    id    = kite.id ? kite.bongo_?.id
    name  = kite.name
    kites[id] ?= {}
    unless kites[id][connType]?
      kites[id][connType] = kite
      kites[id].name      = name
      kites[id].heartbeat = Date.now()
      log.info "kite: #{name} is connected. [#{connType}][#{id}]" 
    else
      kites[id][connType] = kite
      kites[id].name      = name
      kites[id].heartbeat = Date.now()
      log.info "kite: #{name} re-connected. [#{connType}][#{id}]"

    
  @unregisterKite = ({connType,kite,kiteId})->
    
    id    = if kite then kite.id ? kite.bongo_?.id else kiteId

    if connType is "direct"
      if kites[id]?["viaProxy"]?
        delete kites[id]?["direct"] if kites[id]?["direct"]
      else
        delete kites[id] if kites[id]     
    else if connType is "viaProxy"
      if kites[id]?["direct"]?
        delete kites[id]["viaProxy"] if kites[id]?["viaProxy"]
      else
        delete kites[id] if kites[id]

    log.info "kite:#{name?}/#{id} just disconnected or removed by heartbeat.[#{connType}]"
    KiteController.emit "kiteDidDisconnect",id

  
  makeDirectConnToHereFrom=(kite)->
    if kite.api?._connect?
      # log.debug "trying to make a direct connection to:",host:kiteConfig.kfmjsBongoServer.hostname,port:kiteConfig.kfmjsBongoServer.port
      # kite.api._connect host:kiteConfig.kfmjsBongoServer.hostname,port:kiteConfig.kfmjsBongoServer.port
    else
      log.warn "this kite doesn't have _connect() in its api, direct connection is not possible. (#{kite.name})"

  # 
  # bongo.listen kiteConfig.kfmjsBongoServer.port
  # # # # log.debug kiteConfig
  # # accept connections through KiteMasterServer
  # bongo.client.connect
  #   host      : kiteConfig.kiteMasterServer.hostname
  #   port      : kiteConfig.kiteMasterServer.port
  #   reconnect : kiteConfig.kiteMasterServer.reconnect
  # ,(kapi, conn)->
  #   kapi.KiteMasterServer.getKites (err,kites)=>
  #     connType = "viaProxy"
  #     # # # log.debug "getKites",kites
  #     for id,kite of kites
  #       registerKite {kite,connType}
  #       makeDirectConnToHereFrom kite
  #       
  #   kapi.KiteMasterServer.on "newKite",(name,kite)->
  #     connType = "viaProxy"
  #     # # # log.debug "newKite",name,kite        
  #     registerKite {kite,connType}
  #     makeDirectConnToHereFrom kite
  #   kapi.KiteMasterServer.on "kiteDidDisconnect",(kite)->
  #     if kite
  #       connType = "viaProxy"
  #       unregisterKite {kite,connType}
  #     else
  #       log.warn "kiteDidDisconnect but returned #{kite} instead of the kite."  
  # 
  # # accept direct incoming connections
  # bongo.Kite.on "connect",(name,kite)->
  #   connType = "direct"
  #   registerKite {kite,connType}
  #   # log.info "incoming connection accepted from:#{name}"
  #   # # # log.debug @kites
  #   
  # bongo.Kite.on "kiteDidDisconnect",(kite)->
  #   if kite
  #     connType = "direct"
  #     unregisterKite {kite,connType}
  #   else
  #     log.warn "kiteDidDisconnect but returned #{kite} instead of the kite."
