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
      @tell 'info', { machineId }
        .then (info) =>
          @requestingInfo[machineId].forEach ({ resolve }) -> resolve info
          @requestingInfo[machineId] = null
        .timeout ComputeController.timeout
        .catch (err) =>
          warn "kloud.info failed, sending current state back:", { currentState, err }
          @requestingInfo[machineId].forEach ({ resolve }) ->
            resolve State: currentState
          @requestingInfo[machineId] = null
        .finally => @needsRequest[machineId] = yes

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }
