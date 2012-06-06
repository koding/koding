AccountMixin = do ->
  
  init:(api)->
    {JAccount} = api
    
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
      
      sendScrubbedCommand =(url, options)->
        data = JSON.stringify(options)
        $.ajax
          url     : url
          data    :
            data  : data
            env   : if KD.env is 'dev' then 'vpn' else 'beta'
          dataType: 'jsonp'
          # type    : 'POST'
      
      getKiteUri =(kiteName)->
        "https://api.koding.com/1.0/kite/#{kiteName}"
      
      sendCommand =(kiteName, args, callbackId)->
        scrubber = new Scrubber localStore
        scrubber.scrub args, =>
          scrubbed = scrubber.toDnodeProtocol()
          scrubbed.method or= callbackId
          sendScrubbedCommand getKiteUri(kiteName), scrubbed
      
      request = (secretChannelId, callbackId, args)->
        kiteName = secretChannelId.split('-')[1]
        sendCommand kiteName, [{
          toDo      : '_handleCallback'
          withArgs  : args
          secretChannelId
        }], callbackId
      
      getChannel =do ->
        messageHandler =(secretChannelId, args) ->
          callback = localStore.get(args.method)
          scrubber = new Scrubber localStore
          unscrubbed = scrubber.unscrub args, (callbackId)->
            unless remoteStore.has callbackId
              remoteStore.add callbackId, ->
                request secretChannelId, callbackId, [].slice.call arguments
            remoteStore.get callbackId
          callback.apply @, unscrubbed

        (secretChannelId)->
          channel = bongo.mq.channel secretChannelId
          unless channel?
            channel = bongo.mq.subscribe secretChannelId
            channel.bind 'pusher:subscription_succeeded', ->
              myHandler = messageHandler.bind null, secretChannelId
              channel.bind 'message', myHandler
              channel.bind 'error', myHandler
          channel
      
      (options, callback)->
        @fetchKiteChannelName options.kiteName, (err, secretChannelId)=>
          channel = getChannel(secretChannelId)
          options.secretChannelId = secretChannelId
          options.withArgs or= {}
          args = [options, callback]
          sendCommand options.kiteName, args