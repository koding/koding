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

      request =(kiteName, method, args, onMethod='on')-> 
        callbackId = listenerId++
        scrubber = new Scrubber localStore
        scrubber.scrub args, =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method or= method
          fetchChannel kiteName, (channel)=>
            channel[onMethod](
              "reply-client-message.#{callbackId}",
              messageHandler.bind null, kiteName
            )
            channel.emit "client-message.#{callbackId}", JSON.stringify(scrubbed)

      messageHandler =(kiteName, args) ->
        callback = localStore.get(args.method)
        scrubber = new Scrubber localStore
        unscrubbed = scrubber.unscrub args, (callbackId)->
          unless remoteStore.has callbackId
            remoteStore.add callbackId, ->
              request kiteName, callbackId, [].slice.call arguments
          remoteStore.get callbackId
        callback.apply @, unscrubbed

      getChannelName =(kiteName)-> "private-kite-#{kiteName}"

      fetchChannel =(kiteName, callback)->  
        KD.remote.fetchChannel getChannelName(kiteName), callback

      (options, callback=->)->
        scrubber = new Scrubber localStore
        args = [options, callback]
        {method} = options
        onMethod = if options.autoCull is false then 'on' else 'once'
        delete options.autoCull
        request options.kiteName, method, args, onMethod
