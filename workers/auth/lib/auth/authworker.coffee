{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  AUTH_EXCHANGE_OPTIONS =
    type        : 'fanout'
    autoDelete  : yes

  constructor: (@bongo, @resourceName, @presenceExchange='services-presence') ->
    @services = {}
    @clients  = {
      bySocketId    : {}
      byExchange    : {}
      byRoutingKey  : {}
    }
    @counts   = {}

  bound: require 'koding-bound'

  authenticate: (messageData, routingKey, callback) ->
    {clientId, channel, event} = messageData
    @requireSession clientId, routingKey, callback

  requireSession: (clientId, routingKey, callback) ->
    {JSession} = @bongo.models
    JSession.fetchSession clientId, (err, session) =>
      if err? or not session? then @rejectClient routingKey
      else
        tokenHasChanged = session.clientId isnt clientId
        @updateSessionToken session.clientId, routingKey  if tokenHasChanged
        callback session

  updateSessionToken: (clientId, routingKey) ->
    @bongo.respondToClient routingKey,
      method      : 'updateSessionToken'
      arguments   : [clientId]
      callbacks   : {}

  getNextServiceInfo: (serviceType) ->
    count = @counts[serviceType] ?= 0
    servicesOfType = @services[serviceType]
    return  unless servicesOfType?.length
    serviceInfo = servicesOfType[count % servicesOfType.length]
    @counts[serviceType] += 1
    return serviceInfo

  addService: ({serviceGenericName, serviceUniqueName, loadBalancing}) ->
    servicesOfType = @services[serviceGenericName] ?= []
    servicesOfType.push {serviceUniqueName, loadBalancing}

  removeService: ({serviceGenericName, serviceUniqueName}) ->
    servicesOfType = @services[serviceGenericName] 
    [index] = (i for s, i in servicesOfType \
                 when s.serviceUniqueName is serviceUniqueName)
    servicesOfType.splice index, 1
    clientsByExchange = @clients.byExchange[serviceUniqueName]
    clientsByExchange?.forEach @bound 'cycleClient'

  cycleClient: (client) ->
    {routingKey} = client
    @bongo.respondToClient routingKey, {
      method      : 'cycleChannel'
      arguments   : []
      callbacks   : {}
    }

  removeClient: (rest...) ->
    if rest.length is 1
      [client] = rest
      return @removeClient client.socketId, client.exchange, client.routingKey
    [socketId, exchange, routingKey] = rest
    delete @clients.bySocketId[socketId]
    delete @clients.byExchange[exchange]
    delete @clients.byRoutingKey[routingKey]

  addClient: (socketId, exchange, routingKey, sendOk=yes) ->
    if sendOk
      @bongo.respondToClient routingKey, {
        method    : 'authOk'
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

  rejectClient: (routingKey, message) ->
    return console.trace()  unless routingKey?
    @bongo.respondToClient routingKey, {
      method    : 'error'
      arguments : [message: message ? 'Access denied']
      callbacks : {}
    }

  publishToService: (exchangeName, routingKey, payload, callback) ->
    {connection} = @bongo.mq
    connection.exchange exchangeName, AUTH_EXCHANGE_OPTIONS,
      (exchange) =>
        exchange.publish routingKey, payload
        exchange.close() # don't leak a channel
        callback? null

  sendAuthMessage: (options) ->
    { serviceUniqueName, routingKey, method, callback
    username, correlationName, socketId } = options

    params = { routingKey, username, correlationName }

    @publishToService serviceUniqueName, method, params, callback

  sendAuthJoin: (options) ->
    { socketId, serviceUniqueName, routingKey } = options
    options.callback = => @addClient socketId, serviceUniqueName, routingKey
    options.method = 'auth.join'
    @sendAuthMessage options

  sendAuthWho: (options) ->
    options.method = 'auth.who'
    @sendAuthMessage options

  joinClient: do ->

    joinClientHelper = (messageData, routingKey, socketId) ->
      @authenticate messageData, routingKey, (session) =>
        serviceInfo = @getNextServiceInfo messageData.name
        { serviceUniqueName, loadBalancing } = serviceInfo
        params = {
          serviceUniqueName
          routingKey
          username        : session.username
          correlationName : messageData.correlationName
          # maybe the callback wants this:
          socketId
        }
        if loadBalancing
        then @sendAuthWho params
        else if serviceUniqueName?
        then @sendAuthJoin params
        else
          @bongo.respondToClient routingKey, {
            method    : 'error'
            arguments : [message: 'Service unavailable!', code:503]
            callbacks : {}
          }

    ensureGroupPermission = (group, account, roles, callback) ->
      {JPermissionSet, JGroup} = @bongo.models
      client = {context: group.slug, connection: delegate: account}
      JPermissionSet.checkPermission client, "read activity", group,
        (err, hasPermission) ->
          if err then callback err
          else unless hasPermission
            callback {message: 'Access denied!', code: 403}
          else
            JGroup.fetchSecretChannelName group.slug, callback

    joinClientGroupHelper = (messageData, routingKey, socketId) ->
      {JAccount, JGroup} = @bongo.models
      fail = (err) =>
        console.error err  if err
        @rejectClient routingKey
      @authenticate messageData, routingKey, (session) =>
        unless session then fail()
        else JAccount.one {'profile.nickname': session.username},
          (err, account) =>
            if err or not account then fail err
            else JGroup.one {slug: messageData.group}, (err, group) =>
              if err or not group then fail err
              else 
                group.fetchRolesByAccount account, (err, roles) =>
                  if err or not roles then fail err
                  else
                    ensureGroupPermission.call this, group, account, roles,
                      (err, secretChannelName) =>
                        if err or not secretChannelName
                          @rejectClient routingKey
                        else
                          setSecretNameEvent = "#{routingKey}.setSecretName"
                          message = JSON.stringify secretChannelName
                          @bongo.respondToClient setSecretNameEvent, message

    joinClient = (messageData, socketId) ->
      {channel, routingKey, serviceType} = messageData
      switch serviceType
        when 'bongo', 'kite'
          joinClientHelper.call this, messageData, routingKey, socketId
        when 'group'
          console.log {routingKey}
          unless ///^group.#{messageData.group}///.test routingKey
            console.log 'rejecting', routingKey
            return @rejectClient routingKey
          joinClientGroupHelper.call this, messageData, routingKey, socketId
        when 'secret'
          @addClient socketId, routingKey, routingKey, no
        else
          @rejectClient routingKey

  cleanUpClient: (client) ->
    @removeClient client
    @bongo.mq.connection.exchange client.exchange, AUTH_EXCHANGE_OPTIONS,
      (exchange) ->
        exchange.publish 'auth.leave', {
          routingKey: client.routingKey
        }
        exchange.close() # don't leak a channel!

  cleanUpAfterDisconnect: (socketId) ->
    @clients.bySocketId[socketId]?.forEach @bound 'cleanUpClient'

  parseServiceKey = (serviceKey) ->
    last = null
    serviceInfo = serviceKey.split('.').reduce (acc, edge, i)->
      unless i % 2 then last = edge
      else acc[last] = edge
      return acc
    , {}
    serviceInfo.loadBalancing = /\.loadBalancing$/.test serviceKey
    isValidKey  = serviceInfo.serviceGenericName? and
                  serviceInfo.serviceUniqueName?
    throw {
      message: 'Bad service key!'
      serviceKey
      serviceInfo
    }  unless isValidKey

    return serviceInfo

  monitorPresence: (connection) ->
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

  connect: ->
    {bongo} = this
    bongo.mq.ready =>
      {connection} = bongo.mq
      @monitorPresence connection

      connection.exchange 'authAll', AUTH_EXCHANGE_OPTIONS, (authAllExchange) =>
        connection.queue '', {exclusive:yes}, (authAllQueue) =>
          authAllQueue.bind authAllExchange, ''
          authAllQueue.on 'queueBindOk', =>
            authAllQueue.subscribe (message, headers, deliveryInfo) =>
              {routingKey} = deliveryInfo
              messageStr = "#{message.data}"
              switch routingKey
                when 'broker.clientConnected' then # ignore
                when 'broker.clientDisconnected'
                  @cleanUpAfterDisconnect messageStr

      connection.exchange 'auth', AUTH_EXCHANGE_OPTIONS, (authExchange) =>
        connection.queue  'auth', (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo) =>
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = (try JSON.parse messageStr) or message
              switch routingKey
                when 'kite.join'
                  @addService messageData
                when 'kite.leave'
                  @removeService messageData
                when 'kite.who'
                  # TODO: make sure this is OK for untrusted kites:
                  @sendAuthJoin {
                    serviceUniqueName : messageData.serviceUniqueName
                    routingKey        : messageData.routingKey
                    correlationName   : messageData.correlationName
                    username          : messageData.username
                  }
                when "client.auth"
                  @joinClient messageData, socketId
                else
                  @rejectClient routingKey
