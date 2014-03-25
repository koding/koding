class VMChecker extends KDObject
  [NOTWORKING, READY, RUNNING] = [0..2]

  constructor: (options, data) ->
    super options, data

    @vmList = {}
    @status = NOTWORKING

    @resetTimeout()

    {vmController} = KD.singletons
    vmController.on 'vm.state.info', ({alias, state})  =>
      @resetTimeout()
      @vmList[alias] = state.state
      @updateStatus()


  resetTimeout: ->
    clearTimeout @timer
    @timer = KD.utils.wait KD.config.osKitePollingMs, =>
      @status = NOTWORKING


  updateStatus: ->
    @status = RUNNING
    for own name, status of @vmList
      switch status
        when "RUNNING"
          continue
        else
          @status = READY


  healthCheck: (callback) ->
    status = switch @status
      when NOTWORKING
        "fail"
      when READY
        "pending"
      when RUNNING
        "success"
    callback {status}