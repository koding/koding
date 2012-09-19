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

    JAccount::fetchKiteChannelName = (kiteId, callback)->
      @_kiteChannels or= {}
      kiteChannelId = @_kiteChannels[kiteId]
      return callback null, kiteChannelId if kiteChannelId?
      @fetchKiteChannelId kiteId, (err, kiteChannelId)=>
        if err
          callback err
        else
          @_kiteChannels[kiteId] = kiteChannelId
          callback null, kiteChannelId

    JAccount::tellKite = do->
      {Scrubber, Store} = Bongo.dnodeProtocol

      localStore = new Store
      remoteStore = new Store

      listenerId = 0

      channels = {}

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

      fetchChannel =(kiteName, callback)->  
        channelName = getChannelName(kiteName)
        unless channels[channelName]
          KD.remote.fetchChannel channelName, (channel) ->
            channels[channelName] = channel
            callback channel
        else
          callback channels[channelName]

      (options, callback=->)->
        scrubber = new Scrubber localStore
        args = [options, callback]
        {method} = options
        delete options.autoCull
        request options.kiteName, method, args
