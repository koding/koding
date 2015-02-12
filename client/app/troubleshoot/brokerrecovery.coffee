class BrokerRecovery extends KDObject

  constructor: (options = {}, data) ->
    options.timeout ?= 10000
    super options, data

    @unsuccessfulAttempt = 0
    @broker = KD.remote.mq
    KD.utils.repeat options.timeout, @bound "checkStatus"

    @on "brokerNotResponding", =>
      @changeBroker()  if @unsuccessfulAttempt > 2

    @broker.on "ready", =>
      @emit "brokerConnected"

  brokerURL:->
    @broker.sockURL.replace("/subscribe", "")

  checkStatus: ->
    {timeout} = @getOptions()
    if @broker.lastTo < Date.now() - timeout
      responseTimeout = KD.utils.wait 3000, =>
        @unsuccessfulAttempt++
        @emit "brokerNotResponding"

        brokerURL = @brokerURL()
        KD.utils.warnAndLog 'broker not responding', {@unsuccessfulAttempt, brokerURL}

      @broker.ping =>
        @unsuccessfulAttempt = 0
        KD.utils.killWait responseTimeout

  changeBroker: ->
    # every time it will try to connect another broker, but here we are not
    # checking for the previous unsuccessful attempts
    @unsuccessfulAttempt = 0
    @broker.disconnect no
    @broker.selectAndConnect [@brokerURL()]


  recover: (callback) ->
    @once "brokerConnected", callback

    @changeBroker()