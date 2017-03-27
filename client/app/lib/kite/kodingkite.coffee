debug      = (require 'debug') 'kodingkite'

kd         = require 'kd'
kitejs     = require 'kite.js'
Promise    = require 'bluebird'
KiteCache  = require './kitecache'
KiteLogger = require '../kitelogger'


module.exports = class KodingKite extends kd.Object

  @constructors = {}

  @Error = kitejs.Kite.Error

  [DISCONNECTED, CONNECTED] = [0, 1]

  MAX_WAITING_TIME = 60000 # 1 min.
  MAX_QUEUE_SIZE   = 50    # Limit for the callbacks in
                           # the connection waiting queue ~ GG

  init: ->

    @connect()
    Promise.resolve()


  constructor: (options) ->

    super options

    { name } = options

    @on 'open', =>
      @isDisconnected = no # This one is for the manual disconnect request ~ GG
      @_state = CONNECTED

    @on 'close', (reason) =>
      kd.log 'Disconnected with reason:', reason
      @_state = DISCONNECTED

      return  unless @transport?

      { options: { autoReconnect } } = @transport
      @emit 'reconnect'  if not @isDisconnected and autoReconnect


    @waitingCalls = []
    @waitingPromises = []

    @_kiteInvalidError =
      name    : 'KiteInvalid'
      message : "Kite is invalid. This kite (#{name}) not exists
                 or there is a problem with connection."


  setTransport: (@transport) ->

    if @transport?.ws?
      @transport.disconnect()

    @forwardEvent @transport, 'close'
    @forwardEvent @transport, 'open'

    @emit 'ready'


  tell: (rpcMethod, params, callback) ->

    { name } = @getOptions()

    @connect()

    unless @invalid

      _resolve = null
      _args    = null

      promise = new Promise (resolve, reject) =>

        _resolve = resolve
        _args    = [rpcMethod, [params], callback]

        KiteLogger.queued name, rpcMethod, params

        @waitForConnection _args

          .timeout MAX_WAITING_TIME

          .then (args) =>

            KiteLogger.started name, rpcMethod, params

            resolve (@transport?.tell args...

              .then (res) ->

                KiteLogger.success name, rpcMethod, params
                return res

              .catch (err) =>

                if _errPromise = @handleKiteError err, args
                  return _errPromise

                KiteLogger.failed name, rpcMethod, params, err
                throw err

            )

            return args

          .catch (err) =>

            KiteLogger.failed name, rpcMethod, params, err
            reject @_kiteInvalidError

      unless @_state is CONNECTED
        @waitingPromises.push [_resolve, _args]

      promise

    else

      console.warn '[KITE][INVALID]', this

      KiteLogger.failed name, rpcMethod, params
      Promise.reject @_kiteInvalidError


  handleKiteError: (err, args) ->

    return  unless err.name is 'KiteError'

    name = @getOption 'name'

    debug 'handleKiteError', err, args

    # In any case unset KiteCache if there is an authenticationError
    if err.type is 'authenticationError'
      KiteCache.unset name

    # If it was because token is expired try to recover it
    if err.message in ['token is expired', 'session is closed']
      debug 'handleKiteError: a known error catched:', err.message, err
      return new Promise (resolve, reject) =>
        if @transport
          debug 'handleKiteError: transport found calling .expireToken', @transport.getToken()
          @transport.expireToken =>
            debug 'handleKiteError: expireToken returned', @transport.getToken()
            resolve @transport.tell args...
        else
          reject()

    # If not and the kite is kloud, make sure it's destroyed
    else if name is 'kloud'
      delete kd.singletons.kontrol.kites?.kloud?.singleton

    return null


  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) -> @tell rpcMethod, payload


  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      this::[method] = @createMethod @prototype, { method, rpcMethod }


  connect: ->

    return  if @_state is CONNECTED
    @ready => @transport?.connect()


  disconnect: ->

    @isDisconnected = yes

    if @transport
    then @transport.disconnect()
    else @emit 'close', { reason: 'user action' }


  reconnect: ->

    @emit 'reconnect'

    # With a very corrupted connection
    # it's possible to have an empty @transport object ~GG
    @transport?.disconnect?()

    kd.utils.wait 1000, =>
      @transport?.connect?()


  waitForConnection: (args) ->

    { name } = @getOptions()

    new Promise (resolve, reject) =>
      return resolve args if @_state is CONNECTED
      if @waitingCalls.length >= MAX_QUEUE_SIZE
        kd.warn "Call rejected for #{name} kite, queue has #{MAX_QUEUE_SIZE} items."
        return reject()

      cid = (@waitingCalls.push args) - 1

      @once 'open', =>

        resolve @waitingCalls[cid]
        delete  @waitingCalls[cid]
