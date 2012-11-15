AccountMixin = do ->
  init:(api)->
    {JAccount, JGuest} = api

    JGuest::fetchNonce = ->

    nonces = []

    fetchNonces = (callback)->
      KD.whoami().fetchNonces (err, moreNonces)->
        if err
          new KDNotificationView
            title: 'Could not authorize this client.'
        else
          nonces = nonces.concat moreNonces
        callback nonces

    fetchNonce = (callback)->
      nonce = nonces.shift()
      if nonce? then callback nonce
      else fetchNonces -> fetchNonce callback

    JAccount::fetchNonce = fetchNonce

    # JAccount::fetchKiteChannelName = (kiteId, callback)->
    #   console.log 'kiteId', kiteId
    #   @_kiteChannels or= {}
    #   kiteChannelId = @_kiteChannels[kiteId]
    #   return callback null, kiteChannelId if kiteChannelId?
    #   @fetchKiteChannelId kiteId, (err, kiteChannelId)=>
    #     if err
    #       callback err
    #     else
    #       @_kiteChannels[kiteId] = kiteChannelId
    #       callback null, kiteChannelId

    JAccount::tellKite = do->
      {Scrubber, Store} = Bongo.dnodeProtocol

      localStore = new Store
      remoteStore = new Store

      listenerId = 0

      channels = {}

      KD.remote.mq.subscribe('public-status').on 'processIsDead', (data = {})->
        {processName} = data
        kiteName = "private-kite-#{processName}"
        delete KD.remote.mq.channels[kiteName]
        delete channels[kiteName]

      scrub = (method, args, callback) ->
        scrubber = new Scrubber localStore
        scrubber.scrub args, =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method or= method
          callback scrubbed

      request =(kiteName, method, args, onMethod='on')-> 
        scrub method, args, (scrubbed) ->
          declaredBefore = channels[getChannelName(kiteName)]
          fetchChannel kiteName, (channel)->
            unless declaredBefore?
              channel[onMethod](
                "reply-client-message",
                messageHandler.bind null, kiteName
              )
            channel.emit "client-message", JSON.stringify(scrubbed)

      response = (kiteName, method, args) ->
        scrub method, args, (scrubbed) ->
          fetchChannel kiteName, (channel)=>
            channel.emit "client-message", JSON.stringify(scrubbed)

      messageHandler =(kiteName, args) ->
        callback = localStore.get(args.method)
        scrubber = new Scrubber localStore
        unscrubbed = scrubber.unscrub args, (callbackId)->
          unless remoteStore.has callbackId
            remoteStore.add callbackId, ->
              response kiteName, callbackId, [].slice.call(arguments)
          remoteStore.get callbackId
        callback.apply @, unscrubbed

      getChannelName =(kiteName)-> "private-kite-#{kiteName}"

      # A helper to delay a call until some condition is met
      # Types:
      #  condition = func() -> boolean
      #  delay = integer (optional), default is 100ms.
      #  callback = func()
      waitUntil = (condition, delay, callback) ->
        unless callback
          callback = delay
          delay = 100
        g = ->
          if condition()
            callback()
            clearInterval h
        h = setInterval g, delay

      fetchChannel =(kiteName, callback)-> 
        channelName = getChannelName(kiteName)
        unless channels[channelName]
          # Use a cheap hack to ensure the next immediate call to
          # this will not fetch channel again
          channels[channelName] = true
          KD.remote.fetchChannel channelName, (channel) ->
            channels[channelName] = channel
            callback channel
        else
          # Because we set channels[channelName] to true when there
          # are consecutive calls to this, we want it to be a Channel
          # instead, so we wait until the first call is finish.
          condition = -> channels[channelName] instanceof Channel
          waitUntil condition, ->
            callback channels[channelName]

      (options, callback=->)->
        scrubber = new Scrubber localStore
        args = [options, callback]
        {method} = options
        delete options.autoCull
        request options.kiteName, method, args
