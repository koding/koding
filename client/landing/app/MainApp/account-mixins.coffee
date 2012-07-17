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
      {Scrubber, Store} = bongo.dnodeProtocol

      localStore = new Store
      remoteStore = new Store
      
      transports = {}
      
      changeTransport = (channelId, {transport})->
        log 'CHANGING TRANSPORT: ', transport
        transports[channelId] = transport
      
      sendScrubbedCommand =(channelId, url, options)->
        transport = transports[channelId]
        data =
          data    : JSON.stringify(options)
          env     : KD.env
        switch transport
          when 'mq'
            fetchChannel channelId, (channel)->
              channel.trigger 'client-message', data
          else
            fetchNonce (nonce)->
              data.n = nonce
              $.ajax {
                data
                url       : url
                dataType  : 'json'
                type      : 'POST'
                xhrFields :
                  withCredentials: yes
              }
      
      getKiteUri =(kiteName)-> KD.apiUri+"/1.0/kite/#{kiteName}"
      
      sendCommand =(channelId, kiteName, args, callbackId)->
        scrubber = new Scrubber localStore
        scrubber.scrub args, =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method or= callbackId
          sendScrubbedCommand channelId, getKiteUri(kiteName), scrubbed
      
      request = (secretChannelId, callbackId, args)->
        kiteName = secretChannelId.split('-')[1]
        sendCommand secretChannelId, kiteName, [{
          toDo      : '_handleCallback'
          withArgs  : args
          secretChannelId
        }], callbackId
      
      fetchChannel =do ->
        messageHandler =(secretChannelId, args) ->
          callback = localStore.get(args.method)
          scrubber = new Scrubber localStore
          unscrubbed = scrubber.unscrub args, (callbackId)->
            unless remoteStore.has callbackId
              remoteStore.add callbackId, ->
                request secretChannelId, callbackId, [].slice.call arguments
            remoteStore.get callbackId
          callback.apply @, unscrubbed

        (secretChannelId, callback)->
          channel = bongo.mq.channel secretChannelId
          if channel?
            callback channel
          else
            channel = bongo.mq.subscribe secretChannelId
            channel.bind 'pusher:subscription_succeeded', ->
              # join an extra channel here so that we can listen for the vacated webhook.
              connChannel = bongo.mq.subscribe secretChannelId+'-conn'
              connChannel.bind 'pusher:subscription_succeeded', ->
                # log 'SUBSCRIPTION SUCCEEDED', secretChannelId
                myMessageHandler = messageHandler.bind null, secretChannelId
                channel.bind 'message', myMessageHandler
                channel.bind 'error', myMessageHandler
                channel.bind 'changeTransport', changeTransport.bind null, secretChannelId
                callback channel
      
      (options, callback)->
        @fetchKiteChannelName options.kiteName, (err, secretChannelId)->
          fetchChannel secretChannelId, (channel)->
            options.secretChannelId = secretChannelId
            options.withArgs or= {}
            args = [options, callback]
            sendCommand secretChannelId, options.kiteName, args