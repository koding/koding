class NewKite extends KDEventEmitter

  constructor: (@kiteName)->
    super
    @readyState = false
    @localStore = {}
    @getKiteAddr()

  createWebSocket: (url) ->
    new WebSocket "ws://#{url}/sock"

  getKiteAddr:()->
    requestData =
      name       : "#{KD.nick()}"
      remoteKite : @kiteName
      token      : KD.remote.getSessionToken()

    $.ajax
     type    : "POST"
     url     : "http://127.0.0.1:4000/request" #kontrol addr
     data    : JSON.stringify requestData
     success: (data, status, response) =>
       if response.status is 200
         data = JSON.parse data

         console.log "Remote Kite is #{data[0].name}"
         console.log "Addr to be connected is #{data[0].addr}"
         console.log "Token to use is #{data[0].token}"

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
      {id, result, error} = JSON.parse evt.data
      id = "#{id}"
      @localStore[id].call null, error, result

      delete @localStore[id]
    catch e
      console.log "json parse error: ", evt.data

    # @websocket.close()

  onError : (evt) -> console.log "#{@kiteName}: Error #{evt.data}"

  ready:(callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  call : (methodName, rest..., callback)->
    if not KD.isLoggedIn()
      return

    id = Bongo.createId 12

    request =
      name      : "#{KD.whoami().profile.nickname}"
      method    : "#{@kiteName}.#{methodName}"
      params    : rest
      token     : "124"
      id        : id
    # store callback at localstore
    @localStore[id] = callback
    # send query over websocket
    @websocket.send JSON.stringify(request)

  # wrapper function for call method
  tell:(rest...)-> @ready => @call rest...
