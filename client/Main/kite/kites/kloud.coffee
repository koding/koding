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
    {klient}   = kontrol.kites
    machineUid = computeController.findUidFromMachineId machineId

    if not klient? or not machineId?
      return callback null

    klientKite = klient[machineUid]

    if not klientKite?
      return callback null

    KD.remote.api.DataDog.increment "KlientInfo", noop

    klientKite.ping()

      .then (res)->

        if res is "pong"
        then callback State: Machine.State.Running, via: "klient"
        else callback null

      .timeout 5000

      .catch ->

        callback null


  askInfoFromKloud: (machineId, currentState) ->

    KD.remote.api.DataDog.increment "KloudInfo", noop

    @tell 'info', { machineId }

      .then (info) =>

        @resolveRequestingInfos machineId, info

      .timeout ComputeController.timeout

      .catch (err) =>

        warn "[kloud:info] failed, sending current state back:", { currentState, err }
        @resolveRequestingInfos machineId, State: currentState
