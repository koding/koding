class Kontrol extends KDObject

  bound: Bongo.bound

  [NOTREADY, READY, CLOSED] = [0,1,3]

  kontrolEndpoint = "http://#{KD.config.newkontrol.host}:#{KD.config.newkontrol.port}/request"

  constructor: (options)->
    super
    @readyState = NOTREADY
    @addr = "ws://#{KD.config.newkontrol.host}:#{KD.config.newkontrol.port}/_moh_/pub" #kontrol addr
    @connect()

  getKites: (kitename, callback)->
    requestData =
      username   : "#{KD.nick()}"
      kitename   : kitename
      sessionID  : KD.remote.getSessionToken()

    xhr = new XMLHttpRequest
    xhr.open "POST", kontrolEndpoint, yes
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    xhr.send JSON.stringify requestData
    xhr.onload = =>
      if xhr.status is 200
        data = JSON.parse xhr.responseText
        callback null, data
      else
        callback xhr.responseText, null

  connect:->
    @ws = new WebSocket @addr, KD.remote.getSessionToken()
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
        msg = JSON.parse msg
        log "Message from Kontrol", {msg}
      catch e
        log "json parse error: ", e, msg
        return

      switch msg.type
        when "KITE_REGISTERED"
          @addKite msg.args.kite, msg.args.token
        when "KITE_DISCONNECTED"
          @removeKite msg.args.kite.name

  addKite: (kite, token) ->
    kite.token = token
    kc = KD.getSingleton("kiteController")
    correlationName = "local-#{KD.nick()}"
    key = kc.getKiteKey kite.name, correlationName
    kiteInstance = kc.createNewKite kite

    # log "ADDING KITE #{kite.kitename} with key #{key}"
    kc.kiteInstances[key] = kiteInstance

  removeKite: (kitename) ->
    kc = KD.getSingleton("kiteController")
    correlationName = "local-#{KD.nick()}"
    key = kc.getKiteKey kitename, correlationName

    # log "REMOVING KITE #{kitename} with key #{key}"
    delete kc.kiteInstances[key]

  onError: (evt) ->
    log "kontrol: error #{evt.data}"

  ready: (callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  subscribe: ->
    @send
      name: "subscribe"
      args:
        key: "kite.start.#{KD.nick()}"

  send: (data) ->
    @ready =>
      try @ws.send JSON.stringify data
      catch e then log e

  blobToString: (blob, callback) ->
    reader = new FileReader()
    reader.readAsText(blob)
    reader.onloadend = ->
      callback reader.result


