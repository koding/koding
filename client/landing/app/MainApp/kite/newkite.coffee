class NewKite extends KDEventEmitter

  constructor: (@kiteName)->
    super
    @readyState = false
    @localStore = {}
    @localMethods = {}
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
      data = JSON.parse evt.data
      {id} = data
      if id
        {result, error} = data
        id = "#{id}"
        @localStore[id].call null, error, result
        delete @localStore[id]
      else
        {method, params} = data
        console.log "method is", method, params[0], @localMethods[method].toString()
        @localMethods[method].call null, params[0]

    catch e
      console.log "error: ", e, evt.data


  onError : (evt) -> console.log "#{@kiteName}: Error #{evt.data}"

  ready:(callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  call : (methodName, rest..., callback)->
    if not KD.isLoggedIn()
      return

    callbacks = []
    for method, value of rest[0]
      if typeof value is "function"
        methodID = "#{method}"
        unless method of @localMethods
          @localMethods[method] = value
          console.log "Adding callback", method
        callbacks.push method

    id = Bongo.createId 12

    # converts something like: fs.readDirectory to ReadDirectory
    [prefix, methodName] = methodName.split "."
    methodName = methodName.capitalize()


    request =
      username  : "#{KD.whoami().profile.nickname}"
      method    : "#{@kiteName}.#{methodName}"
      params    : rest
      callbacks : callbacks
      token     : @token #get via kontrol, needed for authentication
      id        : id

    # store callback at localstore
    @localStore[id] = callback
    # send query over websocket
    #
    @websocket.send JSON.stringify(request)

  # wrapper function for call method
  tell:(rest...)-> @ready => @call rest...
