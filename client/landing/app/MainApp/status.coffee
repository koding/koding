# Responsible for emitting connection related events.
class Status extends KDController
  [NOTSTARTED, CONNECTED, RECONNECTED, DISCONNECTED] = [1..4]
  [UP, DOWN] = [1..2]

  constructor: ->
    super

    @state = NOTSTARTED
    @connectionState = DOWN

    {@remote}= KD

    @remote.on "connected", @bound "connected"
    @remote.on "disconnected", @bound "disconnected"
    @remote.on "sessionTokenChanged", @bound "sessionTokenChanged"
    @remote.on "loggedInStateChanged", @bound "loggedInStateChanged"

  connected: ->
    if @state is NOTSTARTED
      @connectionState = UP
      @state = CONNECTED
      @emit "connected"
    else
      @connectionState = UP
      @state = RECONNECTED
      @emit "reconnected"

  disconnected: (reason) ->
    @connectionState = DOWN
    @state = DISCONNECTED
    @emit "disconnected", reason
    @remote.disconnect()

  internetUp: ->
    @connected()  if @connectionState is DOWN

  internetDown: ->
    @disconnected "internetDown"  if @connectionState is UP

  loggedInStateChanged: (account) ->
    @emit "bongoConnected", account
    @registerBongoAndBroker()
    @registerKites()

  sessionTokenChanged: (token) ->
    @emit "sessionTokenChanged", token

  registerBongoAndBroker: ->
    bongo = KD.remote
    broker = KD.remote.mq
    monitorItems = KD.getSingleton("monitorItems")
    monitorItems.register {bongo, broker}

  registerKites: ->
    kite = KD.getSingleton("kiteController")
    monitorItems = KD.getSingleton("monitorItems")
    kite.on "channelAdded", (channel, name) ->
      monitorItems.getItems()[name] = channel

      channel.on "unresponsive", ->
        KD.troubleshoot()

    kite.on "channelDeleted", (channel, name) ->
      #delete monitorItems.getItems()[name]

KD.registerSingleton "status", new Status
