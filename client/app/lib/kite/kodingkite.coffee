kitejs = require 'kite.js'
Promise = require 'bluebird'
kd = require 'kd'
KDObject = kd.Object
KiteLogger = require '../kitelogger'

module.exports = class KodingKite extends KDObject

  @constructors = {}

  @Error = kitejs.Kite.Error

  [DISCONNECTED, CONNECTED] = [0, 1]
  MAX_QUEUE_SIZE = 50

  constructor: (options) ->
    super options

    { name } = options

    @on 'open', =>
      @isDisconnected = no # This one is the manual disconnect request ~ GG
      @_state = CONNECTED

    @on 'close', (reason)=>
      kd.log "Disconnected with reason:", reason
      @_state = DISCONNECTED

      return  unless @transport?

      {options:{autoReconnect}} = @transport
      @emit 'reconnect'  if not @isDisconnected and autoReconnect


    @waitingCalls = []
    @waitingPromises = []

    @_kiteInvalidError =
      name    : "KiteInvalid"
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

      promise = new Promise (resolve, reject)=>

        _resolve = resolve
        _args    = [rpcMethod, [params], callback]

        KiteLogger.queued name, rpcMethod

        @waitForConnection _args

          .then (args)=>
            KiteLogger.started name, rpcMethod
            resolve (@transport?.tell args...

              .then (res)->

                KiteLogger.success name, rpcMethod
                return res

              .catch (err)=>

                if err.name is 'KiteError' and \
                   err.message is 'token is expired'

                  return new Promise (resolve, reject)=>
                    @transport?.expireToken =>
                      resolve @transport.tell args...

                KiteLogger.failed name, rpcMethod
                throw err

            )

          .catch =>
            KiteLogger.failed name, rpcMethod
            reject @_kiteInvalidError

      unless @_state is CONNECTED
        @waitingPromises.push [_resolve, _args]

      promise

    else

      KiteLogger.failed name, rpcMethod
      Promise.reject @_kiteInvalidError


  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) -> @tell rpcMethod, payload


  @createApiMapping = (api) ->
    for own method, rpcMethod of api
      @::[method] = @createMethod @prototype, { method, rpcMethod }


  connect: ->

    return  if @_state is CONNECTED
    @ready => @transport?.connect()


  disconnect: ->

    @isDisconnected = yes

    if @transport
    then @transport.disconnect()
    else @emit 'close', reason: 'user action'


  reconnect:  ->

    @emit 'reconnect'

    # With a very corrupted connection
    # it's possible to have an empty @transport object ~GG
    @transport?.disconnect?()

    kd.utils.wait 1000, =>
      @transport?.connect?()


  waitForConnection: (args)->

    { name } = @getOptions()

    new Promise (resolve, reject)=>
      return resolve args if @_state is CONNECTED
      if @waitingCalls.length >= MAX_QUEUE_SIZE
        kd.warn "Call rejected for #{name} kite, queue has #{MAX_QUEUE_SIZE} items."
        return reject()

      cid = (@waitingCalls.push args) - 1

      @once 'open', =>

        resolve @waitingCalls[cid]
        delete  @waitingCalls[cid]
