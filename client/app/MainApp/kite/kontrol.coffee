class Kontrol extends KDObject

  bound: Bongo.bound

  [NOTREADY, READY, CLOSED] = [0,1,3]

  kontrolEndpoint = "http://#{KD.config.newkontrol.host}:#{KD.config.newkontrol.port}/query"
  SubscribePrefix = "client"

  constructor: (options)->

    super

    @readyState = NOTREADY
    @addr = "ws://#{KD.config.newkontrol.host}:#{KD.config.newkontrol.port}/_moh_/pub" #kontrol addr
    @kites = {}
    @connect()

  getKites: (options, callback)->
    # find kites that belongs to username.
    {name, region} = options

    queryData =
      username       : "#{KD.nick()}"
      name           : name
      region         : region
      authentication :
        type         : "browser"
        key          : KD.remote.getSessionToken()

    xhr = new XMLHttpRequest
    xhr.open "POST", kontrolEndpoint, yes
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    xhr.send JSON.stringify queryData
    xhr.onload = =>
      if xhr.status is 200
        data = JSON.parse xhr.responseText
        callback null, data
      else
        callback xhr.responseText, null

  getKite: (options, callback)->
    kite = @kites[options.name]
    return callback null, kite if kite?

    # no kites are available, ask kontrol server if any available
    @getKites options, (err, kites) =>
      if err
        log "kontrol request error", err
        callback err, null
      else
        # result might be multiple kites, but we only use one for now
        kite = @createKite kites[0].kite
        @addKite kite
        callback null, kite

  createKite: (kite)->
    kite = new NewKite
      name     : kite.name
      token    : kite.token
      port     : kite.port
      publicIP : kite.publicIP

    return kite

  addKite: (kite) ->
    @kites[kite.name] = kite

  removeKite: (kite) ->
    delete @kites[kite.name]

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
          log "kite registered"
          kite = @createKite msg.args.kite
          @addKite kite
          @emit "KiteRegistered", msg.args.kite
        when "KITE_DISCONNECTED"
          log "kite disconnected"
          @removeKite msg.args.kite
          @emit "KiteDisconnected", msg.args.kite

  onError: (evt) ->
    log "kontrol: error #{evt.data}"

  ready: (callback)->
    return KD.utils.defer callback  if @readyState
    @once 'ready', callback

  subscribe: ->
    @send
      name: "subscribe"
      args:
        key: "#{SubscribePrefix}.#{KD.nick()}"

  send: (data) ->
    @ready =>
      try @ws.send JSON.stringify data
      catch e then log e

  blobToString: (blob, callback) ->
    reader = new FileReader()
    reader.readAsText(blob)
    reader.onloadend = ->
      callback reader.result


