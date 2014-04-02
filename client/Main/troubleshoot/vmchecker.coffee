class VMChecker extends KDObject

  constructor: (options, data) ->
    super options, data

  healthCheck: (callback) ->
    status = "pending"
    {kites} = KD.singletons.vmController
    for own alias, kite of kites
      switch kite.recentState?.state
        when 'RUNNING'
          status = "success"
        when 'FAILED'
          status  = "fail"
          return callback {status}
        when "STOPPED"
          status = "pending"

    callback {status}

  terminalHealthCheck: (callback) ->
    {terminalKites} = KD.singletons.vmController
    failedTerminals = []

    promises = for own _, terminalKite of terminalKites
      terminalKite.webtermPing()
      .catch (err) =>
        {correlationName} = terminalKite
        failedTerminals.push correlationName

    Promise.all(promises).then =>
      failedTerminals.length > 0
    .nodeify callback
