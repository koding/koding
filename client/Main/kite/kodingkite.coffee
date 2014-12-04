class KodingKite extends KDObject

  { @Error } = require 'kite'

  [DISCONNECTED, CONNECTED] = [0, 1]

  constructor: (options) ->
    super options

    { name } = options

    @on 'open', =>
      console.log "CONNECTED to #{name}"
      @_state = CONNECTED
      @emit "connected"

    @on 'close', =>
      console.log "DISCONNECTED from #{name}"
      @_state = DISCONNECTED

    @waitingCalls = []
    @waitingPromises = []

  extractInfoFromWsEvent = (event)->
    {reason, code, wasClean, timestamp, type} = event

    return {reason, code, wasClean, timestamp, type}

  logTransportFailures:->
    if @transport.ws?
      @transport.ws.addEventListener 'close', (event)->
        params = extractInfoFromWsEvent event
        ErrorLog.create 'ws closed', params

      @transport.ws.addEventListener 'error', (event)->
        params = extractInfoFromWsEvent event
        ErrorLog.create 'ws error', params

  getTransport: -> @transport

  setTransport: (@transport) ->
    if @transport?.ws?
      @transport.disconnect()

    @forwardEvent @transport, 'close'
    @forwardEvent @transport, 'open'

    @emit 'ready'

  tell: (rpcMethod, params, callback) ->

    { name } = @getOptions()

    console.log "TELL :: #{name}.#{rpcMethod}"

    @connect()  if not @_connectAttempted or @isDisconnected

    unless @invalid

      promise = new Promise (resolve, reject)=>

        (@waitForConnection [rpcMethod, [params], callback]).then (args)=>
          console.info "# CONNECTED TO #{name} SENDING #{rpcMethod}... "
          resolve @transport?.tell args...

      unless @_state is CONNECTED
        @waitingPromises.push promise

      promise

    else

      Promise.reject
        name    : "KiteInvalid"
        message : "Kite is invalid. This kite (#{name}) not exists
                   or there is a problem with connection."
        err     : @_invalid


  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) -> @tell rpcMethod, payload

  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }


  @constructors = {}


  connect: ->

    if @transport?
      @transport?.connect()
    else
      @once 'ready', =>
        @transport?.connect()
        @_connectAttempted = yes


  disconnect: ->
    @isDisconnected = yes
    @transport?.disconnect()
    @transport = null


  reconnect:  ->
    @transport?.disconnect()

    KD.utils.wait 1000, =>
      @transport?.connect()


  waitForConnection: (args)->

    { name } = @getOptions()

    new Promise (resolve, reject)=>
      return resolve args if @_state is CONNECTED

      cid = (@waitingCalls.push args) - 1

      console.log "# WAITING CALLS ON #{name}:", @waitingCalls

      @once 'connected', ->
        resolve @waitingCalls[cid]
        delete  @waitingCalls[cid]

