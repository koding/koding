class KodingKite_KloudKite extends KodingKite

  @constructors['kloud'] = this

  @createApiMapping
    stop      : 'stop'
    start     : 'start'
    build     : 'build'
    event     : 'event'
    reinit    : 'reinit'
    resize    : 'resize'
    restart   : 'restart'
    destroy   : 'destroy'
    setDomain : 'domain.set'

  constructor: (options) ->
    super options
    @requestingInfo = KD.utils.dict()
    @needsRequest   = KD.utils.dict()

  # first info request sends message to kite requesting info
  # subsequent info requests while the first request is pending
  # will be queued up and resolved by the pending request

  info: ({ machineId }) ->
    if @needsRequest[machineId] in [undefined, yes]
      @needsRequest[machineId] = no
      @tell 'info', { machineId }
        .then (info) =>
          @requestingInfo[machineId].forEach ({ resolve }) -> resolve info
          @requestingInfo[machineId] = null
        .timeout ComputeController.timeout
        .catch (err) =>
          @requestingInfo[machineId].forEach ({ reject }) -> reject err
          @requestingInfo[machineId] = null
        .catch(require('kite').Error.codeIs "107", (err) => ) # SILENCE THIS ERROR!
        .finally => @needsRequest[machineId] = yes

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }
