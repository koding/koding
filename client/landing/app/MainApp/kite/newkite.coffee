class NewKite extends KDEventEmitter

  { Scrubber, Store } = Bongo.dnodeProtocol

  [NOTREADY, READY, CLOSED] = [0,1,3]

  constructor: (options)->
    super
    { @kiteName, @correlationName, @kiteKey } = options
    @localStore   = new Store
    @remoteStore  = new Store
    @autoReconnect = true
    @readyState = NOTREADY
    @token = ""
    @addr = ""
    @initBackoff options  if @autoReconnect
    @connect()

  connect:->
    if @addr
    then @connectDirectly()
    else @getKiteAddr()

  bound: Bongo.bound

  connectDirectly:->
    @ws = new WebSocket "ws://#{@addr}/sock"
    @ws.onopen    = @bound 'onOpen'
    @ws.onclose   = @bound 'onClose'
    @ws.onmessage = @bound 'onMessage'
    @ws.onerror   = @bound 'onError'

  getKiteAddr:()->
    requestData =
      username   : "#{KD.nick()}"
      remoteKite : @kiteName
      token      : KD.remote.getSessionToken()

    url = "http://localhost:4000/request" #kontrol addr

    # $.ajax was used here...
    xhr = new XMLHttpRequest
    xhr.open "POST", url, yes
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    xhr.send JSON.stringify requestData
    xhr.onload = =>
       if xhr.status is 200
         data = JSON.parse xhr.responseText
         @token = data[0].token
         @addr = data[0].addr
         @connectDirectly()

  disconnect:(reconnect=true)->
    @autoReconnect = !!reconnect  if reconnect?
    @ws.close()

  onOpen: ->
    console.log "connected"
    @clearBackoffTimeout()
    @readyState = READY
    @emit 'ready'
    @emit 'connected'

  onClose : (evt) ->
    console.log "#{@kiteName}: Disconnected"
    @readyState = CLOSED
    if @autoReconnect
      KD.utils.defer => @setBackoffTimeout @bound "connect"

  onMessage : (evt) ->
    try
      args = JSON.parse evt.data
      {method} = args
      console.log "received", {args}
      callback = @localStore.get method
      callback.apply this, @unscrub args
    catch e
      console.log "error: ", e, evt.data

  onError : (evt) -> console.log "#{@kiteName}: Error #{evt.data}"

  initBackoff:(options)->
    backoff = options.backoff ? {}
    totalReconnectAttempts = 0
    initalDelayMs = backoff.initialDelayMs ? 700
    multiplyFactor = backoff.multiplyFactor ? 1.4
    maxDelayMs = backoff.maxDelayMs ? 1000 * 15 # 15 seconds
    maxReconnectAttempts = backoff.maxReconnectAttempts ? 50

    @clearBackoffTimeout =->
      totalReconnectAttempts = 0

    @setBackoffTimeout = (fn)=>
      if totalReconnectAttempts < maxReconnectAttempts
        timeout = Math.min initalDelayMs * Math.pow(
          multiplyFactor, totalReconnectAttempts
        ), maxDelayMs
        setTimeout fn, timeout
        totalReconnectAttempts++
      else
        @emit "connectionFailed"

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
      @ready => @send scrubbed

  scrub: (method, args, callback) ->
    scrubber = new Scrubber @localStore
    scrubber.scrub args, =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method or= method
      callback scrubbed

  tell:(options, callback) ->
    @handleRequest options.method, [options, callback]

  send: (data) ->
    try
      if @readyState is READY
        @ws.send JSON.stringify data
        console.log "Sending", {data}
      else
        console.log "I'm still trying to reconnect, slow down..."
    catch e
      @disconnect()

