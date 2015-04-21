Promise = require 'bluebird'
kd = require 'kd'
Machine = require '../../providers/machine'
KiteLogger = require '../../kitelogger'
globals = require 'globals'


module.exports = class KodingKite_KloudKite extends require('../kodingkite')

  SUPPORTED_PROVIDERS = ['koding', 'amazon']

  getProvider = (machineId)->
    kd.singletons.computeController.machinesById[machineId]?.provider

  isManaged = (machineId)->
    (getProvider machineId) is 'managed'

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) ->

      if payload?.machineId?

        provider = getProvider payload.machineId

        if provider not in SUPPORTED_PROVIDERS
          # machine provider is not supported by kloud #{payload.machineId}
          return Promise.reject
            name    : 'NotSupported'
            message : 'Operation is not supported for this VM'

        payload.provider = provider

      @tell rpcMethod, payload

  @createApiMapping
    stop           : 'stop'
    start          : 'start'
    build          : 'build'
    event          : 'event'
    reinit         : 'reinit'
    resize         : 'resize'
    restart        : 'restart'
    destroy        : 'destroy'
    setDomain      : 'domain.set'
    addDomain      : 'domain.add'
    unsetDomain    : 'domain.unset'
    removeDomain   : 'domain.remove'
    createSnapshot : 'createSnapshot'
    deleteSnapshot : 'deleteSnapshot'


  constructor: (options) ->
    super options

    @requestingInfo = kd.utils.dict()
    @needsRequest   = kd.utils.dict()

    @_reconnectedOnce = no

  # first info request sends message to kite requesting info
  # subsequent info requests while the first request is pending
  # will be queued up and resolved by the pending request

  info: ({ machineId, currentState }) ->

    if @needsRequest[machineId] in [undefined, yes]

      @needsRequest[machineId] = no

      # This is for tests, it bypasses klient info state
      if @_disableKlientInfo and not isManaged machineId
        @askInfoFromKloud machineId, currentState
      else
        @askInfoFromKlient machineId, (klientInfo)=>
          if klientInfo?
          then @resolveRequestingInfos machineId, klientInfo
          else @askInfoFromKloud machineId, currentState

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }


  resolveRequestingInfos: (machineId, info)->

    @requestingInfo?[machineId]?.forEach ({ resolve }) ->
      resolve info

    @requestingInfo[machineId] = null
    @needsRequest[machineId]   = yes


  askInfoFromKlient: (machineId, callback) ->

    {kontrol, computeController} = kd.singletons
    {klient} = kontrol.kites
    machine  = computeController.findMachineFromMachineId machineId

    if not machine or not machineId
      return callback null

    managed    = machine.provider is 'managed'
    klientKite = klient?[machine.uid]

    unless klientKite?

      if machine.status.state is Machine.State.Running or managed

        klientKite = kontrol.getKite
          name            : 'klient'
          queryString     : machine.queryString
          correlationName : machine.uid

      else
        return callback null


    klientKite.ping()

      .then (res)->

        if res is 'pong'
          callback State: Machine.State.Running, via: 'klient'
        else
          computeController.invalidateCache machineId
          callback null

      .timeout if managed then 10000 else 5000

      .catch (err)->

        if err?.name is 'TimeoutError' and managed
          callback State: Machine.State.Stopped, via: 'klient'
        else
          KiteLogger.failed 'klient', 'kite.ping'
          callback null


  askInfoFromKloud: (machineId, currentState) ->

    {kontrol, computeController} = kd.singletons

    provider = getProvider machineId

    @tell 'info', { machineId, provider }

      .then (info) =>

        @resolveRequestingInfos machineId, info

        unless info.State is Machine.State.Running
          computeController.invalidateCache machineId

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        if err.name is 'TimeoutError'

          unless @_reconnectedOnce
            kd.warn 'First time timeout, reconnecting to kloud...'
            kontrol.kites.kloud.singleton?.reconnect?()
            @_reconnectedOnce = yes

          KiteLogger.failed 'kloud', 'info'

        kd.warn '[kloud:info] failed, sending current state back:', { currentState, err }
        @resolveRequestingInfos machineId, State: currentState
