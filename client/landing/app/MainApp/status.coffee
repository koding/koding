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

  connect: ->
    @remote.connect()

  disconnect: (options={}) ->
    if "string" is typeof options
      options = autoReconnect : options

    autoReconnect = options.autoReconnect or true
    reason = options.reason or "internetDown"

    @remote.disconnect(autoReconnect)
    @disconnected(reason)

  connected: ->
    @connectionState = UP

    if @state is NOTSTARTED
      @state = CONNECTED
      @emit "connected"
    else
      @state = RECONNECTED
      @emit "reconnected"

  disconnected: () ->
    return "already disconnected"  if @connectionState is DOWN

    @connectionState = DOWN
    @state = DISCONNECTED
    @emit "disconnected", "internetDown"

  internetUp: ->
    @connected()  if @connectionState is DOWN

  internetDown: ->
    if @connectionState is UP
      @disconnect autoReconnect:true

  loggedInStateChanged: (account) ->
    @emit "bongoConnected", account
    @registerBongoAndBroker()
    @registerKites()

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
        KD.troubleshoot()

    kite.on "channelDeleted", (channel, name) ->
      delete monitorItems.getItems()[name]

  sessionTokenChanged: (token) ->
    @emit "sessionTokenChanged", token
