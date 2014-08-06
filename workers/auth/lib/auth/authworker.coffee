{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  AUTH_EXCHANGE_OPTIONS =
    type        : 'fanout'
    autoDelete  : yes

  REROUTING_EXCHANGE_OPTIONS =
  USERS_PRESENCE_CONTROL_EXCHANGE_OPTIONS =
    type        : 'fanout'
    autoDelete  : yes

  NOTIFICATION_EXCHANGE_OPTIONS =
    type        : 'topic'
    autoDelete  : yes

  constructor: (@bongo, options = {}) ->

    # instance options
    { @servicesPresenceExchange, @reroutingExchange
      @notificationExchange, @usersPresenceControlExchange
      @presenceTimeoutAmount, @authExchange, @authAllExchange } = options

    # initialize defaults:
    @servicesPresenceExchange     ?= 'services-presence'
    @usersPresenceControlExchange ?= 'users-presence-control'
    @reroutingExchange            ?= 'routing-control'
    @notificationExchange         ?= 'notification'
    @authExchange                 ?= 'auth'
    @authAllExchange              ?= 'authAll'
    @presenceTimeoutAmount        ?= 1000 * 60 * 2 # 2 min

    # instance state
    @services         = {}
    @clients          =
      bySocketId      : {}
      byExchange      : {}
      byRoutingKey    : {}
    @usersBySocketId  = {}
    @counts           = {}
    @waitingAuthWhos  = {}

  bound: require 'koding-bound'

  authenticate: (messageData, routingKey, socketId, callback) ->
    {clientId, channel, event} = messageData
    @requireSession clientId, routingKey, socketId, callback

  requireSession: (clientId, routingKey, socketId, callback) ->
    {JSession} = @bongo.models
    JSession.fetchSession clientId, (err, { session }) =>
      if err? then console.error err
      if err? or not session? then @rejectClient routingKey
      else
        @addUserSocket session.username, socketId  if session.username?
        tokenHasChanged = session.clientId isnt clientId
        @updateSessionToken session.clientId, routingKey  if tokenHasChanged
        callback session

  addUserSocket: (username, socketId) ->
    @usersBySocketId[socketId] = username
    @fetchUserPresenceControlExchange (exchange) ->
      exchange.publish 'auth.join', { username, socketId }

  removeUserSocket: (socketId) ->
    username = @usersBySocketId[socketId]
    return  unless username
    delete @usersBySocketId[username]
    @fetchUserPresenceControlExchange (exchange) ->
      exchange.publish 'auth.leave', { username, socketId }

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

  removeService: ({serviceGenericName, serviceUniqueName}) ->
    servicesOfType = @services[serviceGenericName]
    [index] = (i for s, i in servicesOfType \
                 when s.serviceUniqueName is serviceUniqueName)
    servicesOfType.splice index, 1
    clientsByExchange = @clients.byExchange[serviceUniqueName]
    clientsByExchange?.forEach @bound 'cycleClient'

  cycleClient: (client) ->
    {routingKey} = client
    @bongo.respondToClient routingKey,
      method      : 'cycleChannel'
      arguments   : []
      callbacks   : {}

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
      @bongo.respondToClient routingKey,
        method    : 'auth.authOk'
        arguments : []
        callbacks : {}
    clientsBySocketId   = @clients.bySocketId[socketId]     ?= []
    clientsByExchange   = @clients.byExchange[exchange]     ?= []
    clientsByRoutingKey = @clients.byRoutingKey[routingKey] ?= []
    client = new AuthedClient { routingKey, socketId, exchange }
    clientsBySocketId.push client
    clientsByRoutingKey.push client
    clientsByExchange.push client

  rejectClient:(routingKey, message)->
    # console.log 'rejecting', routingKey
    return console.trace()  unless routingKey?
    @bongo.respondToClient routingKey,
      method    : 'error'
      arguments : [message: message ? 'Access denied']
      callbacks : {}

  setSecretNames:(routingKey, publishingName, subscribingName)->
    setSecretNamesEvent = "#{routingKey}.setSecretNames"
    message = JSON.stringify { publishingName, subscribingName }
    @bongo.respondToClient setSecretNamesEvent, message

  publishToService: (exchangeName, routingKey, payload, callback) ->
    { connection } = @bongo.mq
    connection.exchange exchangeName, AUTH_EXCHANGE_OPTIONS,
      (exchange) =>
        exchange.publish routingKey, payload
        exchange.close() # don't leak a channel
        callback? null


  getWaitingAuthWhoKey = (o) ->
    "#{o.username}!#{o.correlationName}!#{o.serviceGenericName}"

  makeExchangeFetcher =(exchangeName, exchangeOptions)->
    exKey   = "#{exchangeName}_"
    (callback)->
      if @[exKey] then return process.nextTick => callback @[exKey]
      @bongo.mq.connection.exchange(
        @[exchangeName]
        exchangeOptions
        (exchange)=> callback @[exKey] = exchange
      ).on 'error', console.error.bind console

  fetchReroutingExchange: makeExchangeFetcher(
    'reroutingExchange', REROUTING_EXCHANGE_OPTIONS
  )

  fetchNotificationExchange: makeExchangeFetcher(
    'notificationExchange', NOTIFICATION_EXCHANGE_OPTIONS
  )

  fetchUserPresenceControlExchange: makeExchangeFetcher(
    'usersPresenceControlExchange', USERS_PRESENCE_CONTROL_EXCHANGE_OPTIONS
  )

  addBinding:(bindingExchange, bindingKey, publishingExchange, routingKey, suffix = '')->
    suffix = ".#{suffix}"  if suffix.length
    @fetchReroutingExchange (exchange)=>
      exchange.publish 'auth.join', {
        bindingExchange
        bindingKey
        publishingExchange
        routingKey
        suffix
      }

  notify:(routingKey, event, contents)->
    @fetchNotificationExchange (exchange)->
      exchange.publish routingKey, { event, contents }

  respondServiceUnavailable: (routingKey, serviceGenericName) ->
    @bongo.respondToClient routingKey,
      method    : 'error'
      arguments : [{
        message : "Service unavailable! #{routingKey}"
        code    :503
        serviceGenericName
      }]
      callbacks : {}

  join: do ->

    ensureGroupPermission = ({group, account}, callback) ->
      {JGroup} = @bongo.models
      checkGroupPermission.call this, group, account, (err, hasPermission) ->
        if err then callback err
        else if hasPermission
          JGroup.fetchSecretChannelName group.slug, callback
        else
          callback {message: 'Access denied!', code: 403}

    ensureSocialapiChannelPermission = ({group, account, options}, callback) ->
      {SocialChannel} = @bongo.models
      checkGroupPermission.call this, group, account, (err, hasPermission) ->
        if err then callback err
        else if hasPermission
            client =
              context   : group   : group.slug
              connection: delegate: account

            reqOptions =
              type: options.apiChannelType
              name: options.apiChannelName

            SocialChannel.checkChannelParticipation client, reqOptions, (err, res)->
              if err
                console.warn """
                  tries to open an unattended channel:
                  user: #{account.profile.nickname}
                  channelname: #{reqOptions.name}
                  channeltype: #{reqOptions.type}

                """
                return callback err
              SocialChannel.fetchSecretChannelName options, callback

        else
          callback {message: 'Access denied!', code: 403}

    checkGroupPermission = (group, account, callback) ->
      {JPermissionSet, JGroup, SocialChannel} = @bongo.models
      client = {context: {group: group.slug}, connection: delegate: account}
      JPermissionSet.checkPermission client, "read group activity", group,
        callback

    joinGroupHelper =(messageData, routingKey, socketId)->
      {JAccount, JGroup} = @bongo.models
      fail = (err) =>
        console.error err  if err
        @rejectClient routingKey
      @authenticate messageData, routingKey, socketId, (session) =>
        unless session then fail()
        fetchAccountAndGroup.call this, session.username, messageData.group,
          (err, data)=>
            return fail err  if err
            {account, group} = data
            ensureGroupPermission.call this, {group, account},
              (err, secretChannelName) =>
                if err or not secretChannelName
                  @rejectClient routingKey
                else
                  handleSecretnameAndRoutingKey.call this,
                    routingKey,
                    secretChannelName

    handleSecretnameAndRoutingKey = (routingKey, secretChannelName)->
      @addBinding 'broadcast', secretChannelName, 'broker', routingKey
      @setSecretNames routingKey, secretChannelName

    fetchAccountAndGroup= (username, groupSlug, callback)->
      {JAccount, JGroup} = @bongo.models
      JAccount.one {'profile.nickname': username},
        (err, account) ->
          return callback err  if err
          return callback {message: "Account not found"}  if not account
          JGroup.one {slug: groupSlug}, (err, group) ->
            return callback err  if err
            return callback {message: "Group not found"}  if not group
            return callback null, {account, group}

    joinSocialApiHelper =(messageData, routingKey, socketId)->
      {JAccount, JGroup, SocialChannel} = @bongo.models
      fail = (err) =>
        console.error err  if err
        @rejectClient routingKey
      @authenticate messageData, routingKey, socketId, (session) =>
        return fail()  unless session
        fetchAccountAndGroup.call this, session.username, messageData.group,
          (err, data)=>
            return fail err  if err
            {account, group} = data

            options =
              groupSlug      : group.slug
              apiChannelType : messageData.channelType
              apiChannelName : messageData.channelName

            ensureSocialapiChannelPermission.call this, {
              group,
              account,
              options
            } , (err, secretChannelName)=>
              return fail err if err
              unless secretChannelName
                return fail {message: "secretChannelName not set"}
              handleSecretnameAndRoutingKey.call this,
                routingKey,
                secretChannelName

    joinNotificationHelper =(messageData, routingKey, socketId)->
      fail = (err)=>
        console.error err  if err
        @rejectClient routingKey

      @authenticate messageData, routingKey, socketId, (session)=>
        unless session then fail()
        else if session?.username
          @addClient socketId, @reroutingExchange, routingKey, no
          bindingKey = session.username
          @addBinding 'notification', bindingKey, 'broker', routingKey
        else
          @rejectClient routingKey

    joinChatHelper =(messageData, routingKey, socketId)->
      {name} = messageData
      {JName} = @bongo.models
      fail = => @rejectClient routingKey
      @authenticate messageData, routingKey, socketId, (session)=>
        return fail()  unless session?.username?
        JName.fetchSecretName name, (err, secretChannelName)=>
          return console.error err  if err

          personalToken = 'pt' + do require 'hat'

          bindingKey          = "client.#{personalToken}"
          consumerRoutingKey  = "chat.#{secretChannelName}"

          {username} = session

          @addBinding 'chat', bindingKey, 'chat-hose', consumerRoutingKey, username

          @notify username, 'chatOpen', {
            publicName  : name
            routingKey  : personalToken
            bindingKey  : consumerRoutingKey
          }

    joinClient =(messageData, socketId)->
      { routingKey, brokerExchange, serviceType, wrapperRoutingKeyPrefix } = messageData

      switch serviceType
        when 'bongo' then # ignore

        when 'group'
          unless ///^group\.#{messageData.group}\.///.test routingKey
            return @rejectClient routingKey
          joinGroupHelper.call this, messageData, routingKey, socketId

        when 'socialapi'
          unless ///^socialapi\.///.test routingKey
            return @rejectClient routingKey
          joinSocialApiHelper.call this, messageData, routingKey, socketId

        when 'chat'
          joinChatHelper.call this, messageData, routingKey, socketId

        when 'notification'
          unless ///^notification\.///.test routingKey
            return @rejectClient routingKey
          joinNotificationHelper.call this, messageData, routingKey, socketId

        when 'secret'
          @addClient socketId, 'routing-control', wrapperRoutingKeyPrefix, no

        else
          @rejectClient routingKey  unless /^oid./.test routingKey
          # TODO: we're not really handling the oid channels at all (I guess we don't need to) C.T.

  cleanUpClient: (client) ->
    @removeClient client
    @bongo.mq.connection.exchange client.exchange, AUTH_EXCHANGE_OPTIONS,
      (exchange) ->
        exchange.publish 'auth.leave', { routingKey: client.routingKey }
        exchange.close() # don't leak a channel!

  cleanUpAfterDisconnect: (socketId) ->
    @removeUserSocket socketId
    clientServices = @clients.bySocketId[socketId]
    clientServices?.forEach @bound 'cleanUpClient'

  connect: ->
    {bongo} = this
    bongo.on 'connected', =>
      {connection} = bongo.mq

      # FIXME: this is a hack to hold the chat exchange open for the meantime
      connection.exchange 'chat', NOTIFICATION_EXCHANGE_OPTIONS, (chatExchange) ->
        # *chirp chirp chirp chirp*

      connection.exchange @authAllExchange, AUTH_EXCHANGE_OPTIONS, (authAllExchange) =>
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

      connection.exchange @authExchange, AUTH_EXCHANGE_OPTIONS, (authExchange) =>
        connection.queue  @authExchange, (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo) =>
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = (try JSON.parse messageStr) or message
              switch routingKey
                when "client.#{@authExchange}"
                  @join messageData, socketId
                else
                  @rejectClient routingKey
