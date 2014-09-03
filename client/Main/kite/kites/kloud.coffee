class KodingKite_KloudKite extends KodingKite

  @constructors['kloud'] = this

  @createApiMapping
    stop      : 'stop'
    start     : 'start'
    build     : 'build'
    event     : 'event'
    restart   : 'restart'
    destroy   : 'destroy'
    setDomain : 'domain.set'

  constructor: (options) ->
    super options
    @requestingInfo = KD.utils.dict()
    @needsRequest = yes

  # first info request sends message to kite requesting info
  # subsequent info requests while the first request is pending
  # will be queued up and resolved by the pending request

  info: ({ machineId }) ->
    if @needsRequest
      @needsRequest = no
      @tell 'info', { machineId }
        .then (info) =>
          @needsRequest = yes
          @requestingInfo[machineId].forEach ({ resolve }) -> resolve info
          @requestingInfo[machineId] = null
        .timeout ComputeController.timeout
        .catch Promise.TimeoutError, (err) =>
          @requestingInfo[machineId].forEach ({ reject }) -> reject err
          @requestingInfo[machineId] = null
        .catch require('kite').Error.codeIs "107", (err) =>
          # SILENCE THIS ERROR!
          @needsRequest = yes

    new Promise (resolve, reject) =>
      @requestingInfo[machineId] ?= []
      @requestingInfo[machineId].push { resolve, reject }
