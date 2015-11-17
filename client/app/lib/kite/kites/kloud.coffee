Promise = require 'bluebird'
kd = require 'kd'
Machine = require '../../providers/machine'
KiteLogger = require '../../kitelogger'
globals = require 'globals'


module.exports = class KodingKite_KloudKite extends require('../kodingkite')

  SUPPORTED_PROVIDERS = ['koding', 'aws']

  getProvider = (machineId)->
    kd.singletons.computeController.machinesById[machineId]?.provider

  isManaged = (machineId)->
    (getProvider machineId) is 'managed'

  getGroupName = ->
    group = kd.singletons.groupsController?.getCurrentGroup()
    return group?.slug ? 'koding'

  @createMethod = (ctx, { method, rpcMethod }) ->
    ctx[method] = (payload) ->

      if payload?.machineId? and provider = getProvider payload.machineId

        if provider not in SUPPORTED_PROVIDERS
          # machine provider is not supported by kloud #{ payload.machineId }
          return Promise.reject
            name    : 'NotSupported'
            message : 'Operation is not supported for this VM'

        payload.provider = provider

      payload.groupName = getGroupName()

      @tell rpcMethod, payload


  @createApiMapping

    # Eventer
    event           : 'event'

    # Machine related actions, these requires valid machineId
    stop            : 'stop'
    start           : 'start'
    build           : 'build'
    reinit          : 'reinit'
    resize          : 'resize'
    restart         : 'restart'
    destroy         : 'destroy'

    # Admin helpers
    addAdmin        : 'admin.add'
    removeAdmin     : 'admin.remove'

    # Domain managament
    setDomain       : 'domain.set'
    addDomain       : 'domain.add'
    unsetDomain     : 'domain.unset'
    removeDomain    : 'domain.remove'

    # Snapshots
    createSnapshot  : 'createSnapshot'

    # Stack, Teams, Credentials related methods
    bootstrap       : 'bootstrap'
    buildStack      : 'apply'
    checkTemplate   : 'plan'
    checkCredential : 'authenticate'


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

    if machine.status.state is Machine.State.Running or managed
      unless klientKite?
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

    provider  = getProvider machineId
    groupName = getGroupName()

    @tell 'info', { machineId, provider, groupName }

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

        # If kite somehow unregistered from Kontrol and Kloud is failing
        # to find it in Kontrol registry we are getting this `not found`
        # at this point we can assume that the machine is Stopped. But on
        # the other hand, Kloud should also mark this machine as Stopped if
        # it couldn't find it in Kontrol registry ~ GG FIXME: FA
        else if err.message is 'not found' and currentState is Machine.State.Running

          @resolveRequestingInfos machineId, State: Machine.State.Stopped
          KiteLogger.failed 'kloud', 'info'

          kd.warn '[kloud:info] failed, Kite not found in Kontrol registry!', err

          return

        kd.warn '[kloud:info] failed, sending current state back:', { currentState, err }
        @resolveRequestingInfos machineId, State: currentState


  ###*
   * Delete the given snapshot.
   *
   * Note that we're using a custom method here (rather than @createMethod)
   * to default the provider to Koding, as is needed for Machine's that
   * no longer exist. They don't have a provider, because they don't exist.
   *
   * @param {Object} payload
   * @param {String} payload.machineId - The machine that created the snapshot
   * @param {String} payload.snapshotId - The snapshotId to delete.
  ###
  deleteSnapshot: (payload) ->

    if payload?.machineId?

      provider = getProvider payload.machineId
      provider = 'koding'  unless provider

      if provider not in SUPPORTED_PROVIDERS
        # machine provider is not supported by kloud #{payload.machineId}
        return Promise.reject
          name    : 'NotSupported'
          message : 'Operation is not supported for this VM'

      payload.provider = provider

    @tell 'deleteSnapshot', payload
