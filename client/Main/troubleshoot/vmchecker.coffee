class VMChecker extends KDObject

  constructor: (options, data) ->
    super options, data

  healthCheck: (callback) ->
    status = "pending"
    {vmController, kontrol} = KD.singletons

    kites = kontrol.kites.oskite

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
    {vmController, kontrol} = KD.singletons
    kites = kontrol.kites.terminal

    failedTerminals = []

    promises = for own _, terminalKite of kites
      terminalKite.webtermPing()
      .catch (err) =>
        {correlationName} = terminalKite
        failedTerminals.push correlationName

    Promise.all(promises).then =>
      failedTerminals.length > 0
    .nodeify callback
