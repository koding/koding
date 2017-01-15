kd = require 'kd'
remote = require './remote'

# Responsible for emitting connection related events.
module.exports = class Status extends kd.Controller
  [NOTSTARTED, CONNECTED, RECONNECTED, DISCONNECTED] = [1..4]
  [NOTSTARTED, UP, DOWN] = [1..3]

  constructor: ->
    super

    @registerSingleton 'status', this

    @state = NOTSTARTED
    @connectionState = DOWN

    @remote = remote

    @remote.on 'connected', @bound 'connected'
    @remote.on 'disconnected', @bound 'disconnected'
    @remote.on 'sessionTokenChanged', @bound 'sessionTokenChanged'
    @remote.on 'loggedInStateChanged', @bound 'loggedInStateChanged'

  resetLocals: -> delete @disconnectOptions

  connect: -> @remote.connect()

  disconnect: (options = {}) ->
    if 'boolean' is typeof options
      options = { autoReconnect : options }

    kd.log 'status', options

    autoReconnect = options.autoReconnect
    @remote.disconnect(autoReconnect)

    @disconnectOptions = options
    @disconnected()

  connected: ->
    @connectionState = UP

    if @state is NOTSTARTED
      @state = CONNECTED
      @emit 'connected'
    else
      @state = RECONNECTED
      @emit 'reconnected', @disconnectOptions
      @resetLocals()

  disconnected: ->
    return 'already disconnected'  if @connectionState is DOWN

    @connectionState = DOWN
    @state = DISCONNECTED
    @emit 'disconnected', @disconnectOptions


  internetUp: ->
    @connected()  if @connectionState is DOWN

  internetDown: ->
    if @connectionState is UP
      @disconnect { autoReconnect: true, reason: 'internetDown' }

  loggedInStateChanged: (account) ->
    @emit 'bongoConnected', account

  sessionTokenChanged: (token) ->
    @emit 'sessionTokenChanged', token
