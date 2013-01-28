AccountMixin = do ->
  init:(api)->
    {JAccount, JGuest} = api

    JAccount::tellKite = do->
      {Scrubber, Store} = Bongo.dnodeProtocol

      localStore = new Store
      remoteStore = new Store

      listenerId = 0

      channels = {}
      namesCache = {}

      scrub =(method, args, callback) ->
        scrubber = new Scrubber localStore
        scrubber.scrub args, =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method or= method
          callback scrubbed

      request =(kiteName, method, args)->
        scrub method, args, (scrubbed) ->
          fetchChannel kiteName, (channel)->
            messageString = JSON.stringify(scrubbed)
            channel.publish messageString

      response =(kiteName, method, args) ->
        scrub method, args, (scrubbed) ->
          fetchChannel kiteName, (channel)=>
            channel.publish JSON.stringify(scrubbed)

      readyChannels = {}

      onReady = (channel, callback)->
        {name} = channel
        if readyChannels[name] then callback()
        else
          channel.once 'ready', ->
            readyChannels[name] ?= channel
            callback()

      ready =(resourceName)->
        @exchange = resourceName
        @emit 'ready'

      error =(err)->
        cycleChannel.call this
        console.error err

      pong =-> @lastPong = Date.now()

      cycleChannel =->
        @off()
        @stopPinging?()
        delete channels[@name]
        delete namesCache[@authenticationInfo.name]

      messageHandler =(kiteName, args) ->
        {method} = args
        callback =
          if method is 'ready'
            ready.bind this
          else if method is 'error'
            error.bind this
          else if method is 'pong'
            pong.bind this
          else if method is 'cycleChannel'
            cycleChannel.bind this
          else
            callback = localStore.get(args.method) ? ->
        scrubber = new Scrubber localStore
        unscrubbed = scrubber.unscrub args, (callbackId)->
          unless remoteStore.has callbackId
            remoteStore.add callbackId, ->
              response kiteName, callbackId, [].slice.call(arguments)
          remoteStore.get callbackId
        callback.apply this, unscrubbed

      getChannelName =(kiteName)->
        return namesCache[kiteName]  if namesCache[kiteName]
        delegate  = KD.whoami()
        nickname  = delegate?.profile.nickname ?
                    if delegate.guestId then "guest#{delegate.guestId}" ?
                    'unknown'
        channelName = "#{Bongo.createId 128}.#{nickname}.#{kiteName}"
        namesCache[kiteName] = channelName
        return channelName

      fetchChannel =(kiteName, callback)->
        channelName = getChannelName "kite-#{kiteName}"
        return callback readyChannels[channelName]  if readyChannels[channelName]
        channel = KD.remote.mq.subscribe channelName
        kiteController = KD.getSingleton 'kiteController'
        kiteController.channels ?= {}
        kiteController.channels[kiteName] = channel
        channel.cycleChannel = -> cycleChannel.call this
        channels[channelName] = channel
        channel.once 'broker.subscribed', ->
          onReady channel, ->
            callback channel
            i = setInterval ->
              now = Date.now()
              isUnresponsive = channel.lastPong? and (now - channel.lastPong > 6000)
              cycleChannel.call channel  if isUnresponsive
              channel.publish JSON.stringify
                method      : 'ping'
                arguments   : []
                callbacks   : {}
            , 5000
            channel.stopPinging =-> clearInterval i
        channel.setAuthenticationInfo
          serviceType : 'kite'
          name        : "kite-#{kiteName}"
          clientId    : KD.remote.getSessionToken()
        channel.on "message", messageHandler.bind channel, kiteName

      tellKite =(options, callback=->)->
        scrubber = new Scrubber localStore
        args = [options, callback]
        {method, kiteName} = options
        request kiteName, method, args
