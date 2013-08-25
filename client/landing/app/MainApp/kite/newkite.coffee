class NewKite extends KDEventEmitter

  constructor: (@kiteName)->
    super
    @readyState = false
    @localStore = {}
    @websocket = @createWebSocket()
    @registerEvents()

  createWebSocket:-> new WebSocket "ws://127.0.0.1:4000/sock"

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
    {id, result, error} = JSON.parse evt.data
    id = "#{id}"
    @localStore[id].call null, error, result

    delete @localStore[id]

    # @websocket.close()

  onError : (evt) -> console.log "#{@kiteName}: Error #{evt.data}"

  ready:(callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  call : (methodName, rest..., callback)->

    # create a unique id
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
    @websocket.send(JSON.stringify(request));

  # wrapper function for call method
  tell:(rest...)-> @ready => @call rest...