class Kontrol extends KDEventEmitter

  bound: Bongo.bound

  [NOTREADY, READY, CLOSED] = [0,1,3]

  constructor: (options)->
    super
    @readyState = NOTREADY
    @addr = "ws://127.0.0.1:4000/_moh_/pub" #kontrol addr
    @connect()

  connect:->
    @ws = new WebSocket @addr
    @ws.onopen    = @bound 'onOpen'
    @ws.onclose   = @bound 'onClose'
    @ws.onmessage = @bound 'onMessage'
    @ws.onerror   = @bound 'onError'

  onOpen:->
    log "I'm connected to #{@addr}. Yayyy!"
    @readyState = READY
    @emit 'ready'
    @subscribe()

  onClose: (evt) ->
    log "Disconnected from #{@addr}, trying to reconnect"
    @readyState = CLOSED

  onMessage: (evt) ->
    @blobToString evt.data, (msg) =>
      try
        args = JSON.parse msg
      catch e
        log "json parse error: ", e, msg

      log {args}

      switch args.action
        when "AddKite"
          @addKite args
        when "RemoveKite"
          @removeKite args.kitename

  addKite: (kite) ->
    kc = KD.getSingleton("kiteController")
    correlationName = "local-#{KD.nick()}"
    key = kc.getKiteKey kite.kitename, correlationName
    kiteInstance = kc.createNewKite
      addr     : kite.addr
      kitename : kite.kitename
      token    : kite.token

    log "ADDING KITE #{kite.kitename} with key #{key}"
    kc.kiteInstances[key] = kiteInstance

  removeKite: (kitename) ->
    kc = KD.getSingleton("kiteController")
    correlationName = "local-#{KD.nick()}"
    key = kc.getKiteKey kitename, correlationName

    log "REMOVING KITE #{kitename} with key #{key}"
    delete kc.kiteInstances[key]

  onError: (evt) ->
    log "kontrol: error #{evt.data}"

  ready: (callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  subscribe: ->
    log "subscribing"
    @send
      name: "subscribe"
      args:
        key: "kite.start.#{KD.nick()}"

  send: (data) ->
    log "sending", {data}
    @ready =>
      try @ws.send JSON.stringify data
      catch e then log e

  blobToString: (blob, callback) ->
    reader = new FileReader()
    reader.readAsText(blob)
    reader.onloadend = ->
      callback reader.result


