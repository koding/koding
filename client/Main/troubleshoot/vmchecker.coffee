class VMChecker extends KDObject

  constructor: (options, data) ->
    super options, data

  healthCheck: (callback) ->
    status = "success"
    {kites} = KD.singletons.vmController
    for own alias, kite of kites
      switch kite.recentState.state
        when 'RUNNING'
          continue
        when 'FAILED'
          status = "fail"
          return callback {status}
        when "STOPPED"
          status = "pending"

    callback {status}