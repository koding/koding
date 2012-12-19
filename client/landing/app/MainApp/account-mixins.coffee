AccountMixin = do ->
  init:(api)->
    {JAccount, JGuest} = api

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
          # declaredBefore = channels[getChannelName(kiteName)]
          fetchChannel kiteName, (channel)->
            unless declaredBefore?
              channel.on(
                "message",
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

      getChannelName =(kiteName)->
        delegate  = KD.whoami()
        nickname  = delegate?.profile.nickname ?
                    if delegate.guestId then "Guest #{delegate.guestId}" ?
                    'unknown'
        return "#{Bongo.createId 128}.#{nickname}.kite-#{kiteName}"

      fetchChannel =(kiteName, callback)-> 
        channelName = getChannelName(kiteName)
        unless channels[channelName]
          channel = KD.remote.mq.subscribe channelName
          channels[channelName] = channel
          channel.on 'broker.subscribed', -> callback channel
          channel.exchange = kiteName
          channel.setAuthenticationInfo
            serviceType : 'kite'
            name        : "kite-#{kiteName}"
            clientId    : KD.remote.getSessionToken()

      (options, callback=->)->
        scrubber = new Scrubber localStore
        args = [options, callback]
        {method} = options
        delete options.autoCull
        request options.kiteName, method, args
