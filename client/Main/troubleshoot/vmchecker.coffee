class VMChecker extends KDObject
  [NOTWORKING, READY, RUNNING] = [0..2]

  constructor: (options, data) ->
    super options, data

    @vmList = {}
    @status = NOTWORKING

    @resetTimeout()

    {vmController} = KD.singletons
    vmController.on 'vm.state.info', ({alias, state})  =>
      switch state.state
        when "RUNNING"
          @vmList[alias] = "on"
        when "STOPPED"
          @vmList[alias] = "off"
      @updateStatus()

    vmController.on 'vm.progress.start', ({alias, update}) =>
      {message} = update
      switch message
        when "FINISHED"
          @vmList[alias] = "on"
        when "STARTED"
          @vmList[alias] = "starting"
      @updateStatus()

    vmController.on 'vm.progress.stop', ({alias, update}) =>
      {message} = update
      switch message
        when "FINISHED"
          @vmList[alias] = "off"
        when "STARTED"
          @vmList[alias] = "stopping"
      @updateStatus()


  resetTimeout: ->
    clearTimeout @timer
    @timer = KD.utils.wait KD.config.osKitePollingMs, =>
      @status = NOTWORKING


  updateStatus: ->
    @status = RUNNING
    for own name, status of @vmList
      switch status
        when "on"
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