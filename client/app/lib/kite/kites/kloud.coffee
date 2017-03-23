Promise = require 'bluebird'
kd = require 'kd'
KiteLogger = require '../../kitelogger'
globals = require 'globals'
KiteAPIMap = require './kiteapimap'
remote = require 'app/remote'


module.exports = class KodingKiteKloudKite extends require('../kodingkite')

  SUPPORTED_PROVIDERS = globals.config.providers._getSupportedProviders()

  debugEnabled = ->
    kd.singletons.computeController._kloudDebug

  getMachineProvider = (machineId) ->
    cc = kd.singletons.computeController
    machine = cc.findMachineFromMachineId machineId
    return machine?.provider

  getStackProvider = (stackId) ->
    stack = kd.singletons.computeController.findStackFromStackId stackId
    return  unless stack
    for provider in stack.config.requiredProviders
      return provider  if provider in SUPPORTED_PROVIDERS

  isManaged = (machineId) ->
    (getMachineProvider machineId) is 'managed'

  getGroupName = ->
    group = kd.singletons.groupsController?.getCurrentGroup()
    return group?.slug ? 'koding'

  injectCustomData = (payload) ->

    return {}  unless payload

    { machineId, stackId } = payload

    if machineId
      provider = getMachineProvider payload.machineId
    else if stackId
      provider = getStackProvider payload.stackId

    if provider

      if provider not in SUPPORTED_PROVIDERS
        # machine/stack provider is not supported by kloud
        return Promise.reject {
          name    : 'NotSupported'
          message : 'Operation is not supported for this VM/Stack'
        }

      payload.provider = provider

    payload.groupName = getGroupName()
    payload.debug = yes  if debugEnabled()

    return payload


  @createMethod = (ctx, { method, rpcMethod }) ->

    ctx[method] = (payload) ->
      @tell rpcMethod, injectCustomData payload


  @createApiMapping KiteAPIMap.kloud


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
        @askInfoFromKlient machineId, (klientInfo) =>
          if klientInfo?
          then @resolveRequestingInfos machineId, klientInfo
          else @askInfoFromKloud machineId, currentState

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }


  resolveRequestingInfos: (machineId, info) ->

    @requestingInfo?[machineId]?.forEach ({ resolve }) ->
      resolve info

    @requestingInfo[machineId] = null
    @needsRequest[machineId]   = yes


  askInfoFromKlient: (machineId, callback) ->

    { kontrol, computeController } = kd.singletons
    { klient } = kontrol.kites
    machine    = computeController.findMachineFromMachineId machineId
    deferredCallback = (res) -> kd.utils.defer -> callback res

    if not machine or not machineId
      return deferredCallback null

    managed    = machine.isManaged()
    klientKite = klient?[machine.uid]

    unless machine.isBuilt()
      return deferredCallback { State: machine.status.state , via: 'klient' }

    else if machine.isRunning() or managed
      unless klientKite?
        klientKite = kontrol.getKite
          name            : 'klient'
          queryString     : machine.queryString
          correlationName : machine.uid
    else
      return deferredCallback null

    { Running, Stopped } = remote.api.JMachine.State

    klientKite.ping()

      .then (res) ->
        if res is 'pong'
          callback { State: Running, via: 'klient' }
        else
          computeController.invalidateCache machineId
          callback null

      .timeout if managed then 15000 else 5000

      .catch (err) ->

        if err?.name is 'TimeoutError' and managed
          callback { State: Stopped, via: 'klient' }
        else
          KiteLogger.failed 'klient', 'kite.ping'
          callback null


  askInfoFromKloud: (machineId, currentState) ->

    { Running, Stopped } = remote.api.JMachine.State
    { kontrol, computeController } = kd.singletons

    provider  = getMachineProvider machineId
    groupName = getGroupName()

    payload   = { machineId, provider, groupName }
    payload.debug = yes  if debugEnabled()

    @tell 'info', payload

      .then (info) =>

        @resolveRequestingInfos machineId, info

        unless info.State is Running
          computeController.invalidateCache machineId

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        if err.name is 'TimeoutError'

          unless @_reconnectedOnce
            kd.warn 'First time timeout, reconnecting to kloud...'
            kontrol.kites.kloud.singleton?.reconnect?()
            @_reconnectedOnce = yes

          KiteLogger.failed 'kloud', 'info', payload

        # If kite somehow unregistered from Kontrol and Kloud is failing
        # to find it in Kontrol registry we are getting this `not found`
        # at this point we can assume that the machine is Stopped. But on
        # the other hand, Kloud should also mark this machine as Stopped if
        # it couldn't find it in Kontrol registry ~ GG FIXME: FA
        else if err.message is 'not found' and currentState is Running

          @resolveRequestingInfos machineId, { State: Stopped }
          KiteLogger.failed 'kloud', 'info', payload

          kd.warn '[kloud:info] failed, Kite not found in Kontrol registry!', err

          return

        kd.warn '[kloud:info] failed, sending current state back:', { currentState, err }
        @resolveRequestingInfos machineId, { State: currentState }
