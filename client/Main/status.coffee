# Responsible for emitting connection related events.
class Status extends KDController
  [NOTSTARTED, CONNECTED, RECONNECTED, DISCONNECTED] = [1..4]
  [NOTSTARTED, UP, DOWN] = [1..3]

  constructor: ->
    super

    @registerSingleton "status", this

    @state = NOTSTARTED
    @connectionState = DOWN

    {@remote}= KD

    @remote.on "connected", @bound "connected"
    @remote.on "disconnected", @bound "disconnected"
    @remote.on "sessionTokenChanged", @bound "sessionTokenChanged"
    @remote.on "loggedInStateChanged", @bound "loggedInStateChanged"

  resetLocals:-> delete @disconnectOptions

  connect: -> @remote.connect()

  disconnect: (options={}) ->
    if "boolean" is typeof options
      options = autoReconnect : options

    log "status", options

    autoReconnect = options.autoReconnect
    @remote.disconnect(autoReconnect)

    @disconnectOptions = options
    @disconnected()

  connected: ->
    @connectionState = UP

    if @state is NOTSTARTED
      @state = CONNECTED
      @emit "connected"
    else
      @state = RECONNECTED
      @emit "reconnected", @disconnectOptions
      @startPingingKites()
      @resetLocals()

  startPingingKites: ->
    @eachKite (channel)->
      channel.setStartPinging()

  disconnected: ->
    return "already disconnected"  if @connectionState is DOWN

    @stopPingingKites()
    @connectionState = DOWN
    @state = DISCONNECTED
    @emit "disconnected", @disconnectOptions

  stopPingingKites: ->
    @eachKite (channel)->
      channel.setStopPinging()

  eachKite: (callback) ->
    kiteChannels = KD.getSingleton("kiteController").channels
    for own channelName, channel of kiteChannels
      callback(channel)

  internetUp: ->
    @connected()  if @connectionState is DOWN

  internetDown: ->
    if @connectionState is UP
      @disconnect autoReconnect:true, reason:"internetDown"

  loggedInStateChanged: (account) ->
    @emit "bongoConnected", account
    # @registerBongoAndBroker()
    # @registerKites()

  registerBongoAndBroker: ->
    bongo = KD.remote
    broker = KD.remote.mq
    monitorItems = KD.getSingleton "monitorItems"
    monitorItems.register {bongo, broker}

  registerKites: ->
    monitorItems = KD.getSingleton "monitorItems"
    kite = KD.getSingleton "kiteController"

    kite.on "channelAdded", (channel, name) ->
      monitorItems.getItems()[name] = channel

      channel.on "unresponsive", ->
        KD.troubleshoot(false)

    kite.on "channelDeleted", (channel, name) ->
      delete monitorItems.getItems()[name]

  sessionTokenChanged: (token) ->
    @emit "sessionTokenChanged", token
