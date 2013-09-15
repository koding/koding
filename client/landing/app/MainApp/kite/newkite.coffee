class NewKite extends KDEventEmitter

  { Scrubber, Store } = Bongo.dnodeProtocol

  constructor: (options)->
    super

    { @kiteName, @correlationName, @kiteKey } = options

    @localStore   = new Store
    @remoteStore  = new Store

    @readyState = false
    @token = ""
    @getKiteAddr()

  createWebSocket: (url) ->
    new WebSocket "ws://#{url}/sock"

  getKiteAddr:()->
    requestData =
      username   : "#{KD.nick()}"
      remoteKite : @kiteName
      token      : KD.remote.getSessionToken()

    $.ajax
     type    : "POST"
     url     : "http://127.0.0.1:4000/request" #kontrol addr
     data    : JSON.stringify requestData
     success: (data, status, response) =>
       if response.status is 200
         data = JSON.parse data

         console.log "DATA", data

         console.log "Remote Kite belongs to: #{data[0].username}, type: #{data[0].kitename}"
         console.log "Addr to be connected is #{data[0].addr}"
         console.log "Token to use is #{data[0].token}"

         @token = data[0].token
         @websocket = @createWebSocket(data[0].addr)
         @registerEvents()

     error: (data, status, response) ->
       console.log "error kontrol kite request", data, status, response

  registerEvents:()->
    @websocket.onopen = (evt) => @onOpen evt
    @websocket.onclose = (evt) => @onClose evt
    @websocket.onmessage = (evt) => @onMessage evt
    @websocket.onerror = (evt) => @onError evt

  onOpen :(evt) ->
    @readyState = true
    @emit 'ready'

  onClose : (evt) -> console.log "#{@kiteName}: Disconnected"

  onMessage : (evt) ->
    try
      args = JSON.parse evt.data
      {method} = args
      callback = @localStore.get method
      callback.apply this, @unscrub args
      # data = JSON.parse evt.data
      # {id} = data
      # if id
      #   {result, error} = data
      #   id = "#{id}"
      #   @localStore[id].call null, error, result
      #   delete @localStore[id]
      # else
      #   {method, params} = data
      #   console.log "method is", method, params[0], @localMethods[method].toString()
      #   @localMethods[method].call null, params[0]

    catch e
      console.log "error: ", e, evt.data

  onError : (evt) -> console.log "#{@kiteName}: Error #{evt.data}"

  ready:(callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  unscrub: (args) ->
    scrubber = new Scrubber @localStore
    return scrubber.unscrub args, (callbackId) =>
      unless @remoteStore.has callbackId
        @remoteStore.add callbackId, (rest...) =>
          @handleRequest callbackId, rest
      @remoteStore.get callbackId

  handleRequest: (method, args) ->
    console.log {method}, {args}
    @scrub method, args, (scrubbed) =>
      messageString = JSON.stringify(scrubbed)
      console.log {messageString}
      @ready => @websocket.send messageString

  scrub: (method, args, callback) ->
    scrubber = new Scrubber @localStore
    scrubber.scrub args, =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method or= method
      callback scrubbed

  tell:(options, callback) ->
    @handleRequest options.method, [options, callback]

