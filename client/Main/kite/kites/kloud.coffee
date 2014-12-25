class KodingKite_KloudKite extends KodingKite

  @constructors['kloud'] = this

  @createApiMapping
    stop         : 'stop'
    start        : 'start'
    build        : 'build'
    event        : 'event'
    reinit       : 'reinit'
    resize       : 'resize'
    restart      : 'restart'
    destroy      : 'destroy'
    setDomain    : 'domain.set'
    addDomain    : 'domain.add'
    unsetDomain  : 'domain.unset'
    removeDomain : 'domain.remove'


  constructor: (options) ->
    super options
    @requestingInfo = KD.utils.dict()
    @needsRequest   = KD.utils.dict()

    @_reconnectedOnce = no

  # first info request sends message to kite requesting info
  # subsequent info requests while the first request is pending
  # will be queued up and resolved by the pending request

  info: ({ machineId, currentState }) ->

    if @needsRequest[machineId] in [undefined, yes]

      @needsRequest[machineId] = no

      @askInfoFromKlient machineId, (klientInfo)=>

        if klientInfo?

          @resolveRequestingInfos machineId, klientInfo

        else

          @askInfoFromKloud machineId, currentState

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }


  resolveRequestingInfos: (machineId, info)->

    @requestingInfo?[machineId]?.forEach ({ resolve }) ->
      resolve info

    @requestingInfo[machineId] = null
    @needsRequest[machineId]   = yes


  askInfoFromKlient: (machineId, callback) ->

    {kontrol, computeController} = KD.singletons
    {klient} = kontrol.kites
    machine  = computeController.findMachineFromMachineId machineId

    unless machineId?
      return callback null

    klientKite = klient?[machine.uid]

    unless klientKite?

      if machine.status.state is Machine.State.Running

        klientKite = kontrol.getKite
          name            : "klient"
          queryString     : machine.queryString
          correlationName : machine.uid

      else
        return callback null

    klientKite.ping()

      .then (res)->

        if res is "pong"
        then callback State: Machine.State.Running, via: "klient"
        else
          computeController.invalidateCache machineId
          callback null

      .timeout 5000

      .catch ->

        KiteLogger.logFailed 'klient', 'kite.ping'

        callback null


  askInfoFromKloud: (machineId, currentState) ->

    {kontrol, computeController} = KD.singletons

    @tell 'info', { machineId }

      .then (info) =>

        @resolveRequestingInfos machineId, info

        unless info.State is Machine.State.Running
          computeController.invalidateCache machineId

      .timeout ComputeController.timeout

      .catch (err) =>

        if err.name is "TimeoutError"

          unless @_reconnectedOnce
            warn "First time timeout, reconnecting to kloud..."
            kontrol.kites.kloud.singleton?.reconnect?()
            @_reconnectedOnce = yes

          KiteLogger.logFailed 'kloud', 'info'

        warn "[kloud:info] failed, sending current state back:", { currentState, err }
        @resolveRequestingInfos machineId, State: currentState
