{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  AUTH_EXCHANGE_OPTIONS =
    type        : 'fanout'
    autoDelete  : yes

  REROUTING_EXCHANGE_OPTIONS = 
    type        : 'fanout'
    autoDelete  : yes

  constructor:(@bongo, options = {})->
    { @presenceExchange, @reroutingExchange } = options
    @presenceExchange     ?= 'services-presence'
    @reroutingExchange    ?= 'routing-control'
    @services = {}
    @clients  = {
      bySocketId    : {}
      byExchange    : {}
      byRoutingKey  : {}
    }
    @counts   = {}

  bound: require 'koding-bound'

  authenticate:(messageData, routingKey, callback)->
    {clientId, channel, event} = messageData
    @requireSession clientId, routingKey, callback

  requireSession:(clientId, routingKey, callback)->
    {JSession} = @bongo.models
    JSession.fetchSession clientId, (err, session)=>
      if err? or not session? then @rejectClient routingKey
      else
        tokenHasChanged = session.clientId isnt clientId
        @updateSessionToken session.clientId, routingKey  if tokenHasChanged
        callback session

  updateSessionToken:(clientId, routingKey)->
    @bongo.respondToClient routingKey,
      method      : 'updateSessionToken'
      arguments   : [clientId]
      callbacks   : {}

  getNextServiceName:(serviceType)->
    count = @counts[serviceType] ?= 0
    servicesOfType = @services[serviceType]
    return  unless servicesOfType?.length
    serviceName = servicesOfType[count % servicesOfType.length]
    @counts[serviceType] += 1
    return serviceName

  addService:({serviceGenericName, serviceUniqueName})->
    servicesOfType = @services[serviceGenericName] ?= []
    servicesOfType.push serviceUniqueName 

  removeService:({serviceGenericName, serviceUniqueName})->
    servicesOfType = @services[serviceGenericName] 
    index = servicesOfType.indexOf serviceUniqueName
    servicesOfType.splice index, 1
    clientsByExchange = @clients.byExchange[serviceUniqueName]
    clientsByExchange?.forEach @bound 'cycleClient'

  cycleClient:(client)->
    {routingKey} = client
    @bongo.respondToClient routingKey, {
      method      : 'cycleChannel'
      arguments   : []
      callbacks   : {}
    }

  removeClient:(rest...)->
    if rest.length is 1
      [client] = rest
      return @removeClient client.socketId, client.exchange, client.routingKey
    [socketId, exchange, routingKey] = rest
    delete @clients.bySocketId[socketId]
    delete @clients.byExchange[exchange]
    delete @clients.byRoutingKey[routingKey]

  addClient:(socketId, exchange, routingKey, sendOk=yes)->
    if sendOk
      @bongo.respondToClient routingKey, {
        method    : 'auth.authOk'
        arguments : []
        callbacks : {}
      }
    clientsBySocketId   = @clients.bySocketId[socketId]     ?= []
    clientsByExchange   = @clients.byExchange[exchange]     ?= []
    clientsByRoutingKey = @clients.byRoutingKey[routingKey] ?= []
    client = new AuthedClient {routingKey, socketId, exchange}
    clientsBySocketId.push client
    clientsByRoutingKey.push client
    clientsByExchange.push client

  rejectClient:(routingKey, message)->
    console.log 'rejecting', routingKey
    return console.trace()  unless routingKey?
    @bongo.respondToClient routingKey, {
      method    : 'error'
      arguments : [message: message ? 'Access denied']
      callbacks : {}
    }

  setSecretName:(routingKey, secretChannelName)->
    setSecretNameEvent = "#{routingKey}.setSecretName"
    message = JSON.stringify secretChannelName
    @bongo.respondToClient setSecretNameEvent, message

  fetchReroutingExchange:(callback)->
    @bongo.mq.connection.exchange(
      @reroutingExchange
      REROUTING_EXCHANGE_OPTIONS
      callback
    )

  addBinding:(exchangeName, bindingKey, routingKey)->
    @fetchReroutingExchange (exchange)=>
      exchange.publish 'auth.join', {
        exchange: exchangeName
        bindingKey
        routingKey
      }

  _fakePersistenceWorker:(secretChannelName)->
    {connection} = @bongo.mq
    options = {type: 'fanout', autoDelete: yes, durable: no}
    connection.exchange secretChannelName, options, (exchange)->
      connection.queue '', {autoDelete: yes, durable: no, exclusive: yes}, (queue)->
        queue.bind exchange, '#'
        queue.on 'queueBindOk', ->
          queue.subscribe (message)->
            console.log message.data+''

  join: do ->

    joinHelper =(messageData, routingKey, socketId)->
      @authenticate messageData, routingKey, (session)=>
        serviceResourceName = @getNextServiceName messageData.name
        unless serviceResourceName?
          @bongo.respondToClient routingKey, {
            method    : 'error'
            arguments : [message: 'Service unavailable!', code:503]
            callbacks : {}
          }
        else
          {connection} = @bongo.mq
          connection.exchange serviceResourceName, AUTH_EXCHANGE_OPTIONS,
            (exchange)=>
              exchange.publish 'auth.join', {
                username    : session.username
                routingKey  : routingKey
              }
              exchange.close() # don't leak a channel
              @addClient socketId, exchange.name, routingKey

    ensureGroupPermission =(group, account, roles, callback)->
      {JPermissionSet, JGroup} = @bongo.models
      client = {context: group.slug, connection: delegate: account}
      JPermissionSet.checkPermission client, "read activity", group,
        (err, hasPermission)->
          if err then callback err
          else unless hasPermission
            callback {message: 'Access denied!', code: 403}
          else
            JGroup.fetchSecretChannelName group.slug, callback

    joinGroupHelper =(messageData, routingKey, socketId)->
      {JAccount, JGroup} = @bongo.models
      fail = (err)=>
        console.error err  if err
        @rejectClient routingKey
      @authenticate messageData, routingKey, (session)=>
        unless session then fail()
        else JAccount.one {'profile.nickname': session.username},
          (err, account)=>
            if err or not account then fail err
            else JGroup.one {slug: messageData.group}, (err, group)=>
              if err or not group then fail err
              else 
                group.fetchRolesByAccount account, (err, roles)=>
                  if err or not roles then fail err
                  else
                    ensureGroupPermission.call this, group, account, roles,
                      (err, secretChannelName)=>
                        if err or not secretChannelName
                          @rejectClient routingKey
                        else
                          @setSecretName routingKey, secretChannelName

    joinNotificationHelper =(messageData, routingKey, socketId)->
      fail = (err)=>
        console.error err  if err
        @rejectClient routingKey

      @authenticate messageData, routingKey, (session)=>
        unless session then fail()
        else if session?.username
          @addClient socketId, @reroutingExchange, routingKey, no
          bindingKey = session.username
          @addBinding 'notification', bindingKey, routingKey
        else
          @rejectClient routingKey

    joinChatHelper =(messageData, routingKey, socketId)->
      {name} = messageData
      {JName} = @bongo.models
      JName.fetchSecretName name, (err, secretChannelName)=>
        return console.error err  if err

        personalToken = do require 'hat'
        
        @addBinding 'chat', secretChannelName, personalToken

        @_fakePersistenceWorker secretChannelName
        @setSecretName routingKey, personalToken

    join =(messageData, socketId)->
      {channel, routingKey, serviceType} = messageData
      switch serviceType
        when 'bongo', 'kite'
          joinHelper.call this, messageData, routingKey, socketId
        
        when 'group'
          unless ///^group\.#{messageData.group}\.///.test routingKey
            return @rejectClient routingKey
          joinGroupHelper.call this, messageData, routingKey, socketId
        
        when 'chat'
          joinChatHelper.call this, messageData, routingKey, socketId
        
        when 'notification'
          unless ///^notification\.///.test routingKey
            return @rejectClient routingKey
          joinNotificationHelper.call this, messageData, routingKey, socketId

        when 'secret'
          @addClient socketId, routingKey, routingKey, no
        
        else
          @rejectClient routingKey  unless /^oid./.test routingKey
          # TODO: we're not really handling the oid channels at all (I guess we don't need to) C.T.

  cleanUpClient:(client)->
    @removeClient client
    @bongo.mq.connection.exchange client.exchange, AUTH_EXCHANGE_OPTIONS,
      (exchange)->
        exchange.publish 'auth.leave', {
          routingKey: client.routingKey
        }
        exchange.close() # don't leak a channel!

  cleanUpAfterDisconnect:(socketId)->
    @clients.bySocketId[socketId]?.forEach @bound 'cleanUpClient'

  parseServiceKey =(serviceKey)->
    last = null
    serviceInfo = serviceKey.split('.').reduce (acc, edge, i)->
      unless i % 2 then last = edge
      else acc[last] = edge
      return acc
    , {}
    isValidKey  = serviceInfo.serviceGenericName? and
                  serviceInfo.serviceUniqueName?
    throw {
      message: 'Bad service key!'
      serviceKey
      serviceInfo
    }  unless isValidKey

    return serviceInfo

  monitorPresence:(connection)->
    Presence = require 'koding-rabbit-presence'
    @presence = new Presence {
      connection
      exchange  : @presenceExchange
      member    : @resourceName
    }
    @presence.on 'join', (serviceKey)=>
      try @addService parseServiceKey serviceKey
      catch e then console.error e
    @presence.on 'leave', (serviceKey)=>
      try @removeService parseServiceKey serviceKey
      catch e then console.error e
    @presence.listen()

  connect:->
    {bongo} = this
    bongo.mq.ready =>
      {connection} = bongo.mq
      @monitorPresence connection

      connection.exchange 'authAll', AUTH_EXCHANGE_OPTIONS, (authAllExchange)=>
        connection.queue '', {exclusive:yes}, (authAllQueue)=>
          authAllQueue.bind authAllExchange, ''
          authAllQueue.on 'queueBindOk', =>
            authAllQueue.subscribe (message, headers, deliveryInfo)=>
              {routingKey} = deliveryInfo
              messageStr = "#{message.data}"
              switch routingKey
                when 'broker.clientConnected' then # ignore
                when 'broker.clientDisconnected'
                  @cleanUpAfterDisconnect messageStr

      connection.exchange 'auth', AUTH_EXCHANGE_OPTIONS, (authExchange)=>
        connection.queue  'auth', (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo)=>
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = (try JSON.parse messageStr) or message
              switch routingKey
                when 'kite.join'
                  @addService messageData
                when 'kite.leave'
                  @removeService messageData
                when "client.auth"
                  @join messageData, socketId
                else
                  @rejectClient routingKey
