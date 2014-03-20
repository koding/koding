class BrokerRecovery extends KDObject

  constructor: (options = {}, data) ->
    options.timeout ?= 10000
    super options, data

    @unsuccessfulAttempt = 0
    @broker = if options.type is "kite" then KD.kite.mq \
              else KD.remote.mq
    KD.utils.repeat options.timeout, @bound "checkStatus"

    @on "brokerNotResponding", =>
      if @unsuccessfulAttempt > 2
        @changeBroker()

    @broker.on "ready", =>
      @emit "brokerConnected"


  checkStatus: ->
    {timeout} = @getOptions()
    if @broker.lastTo < Date.now() - timeout
      timeout = KD.utils.wait 3000, =>
        @unsuccessfulAttempt++
        @emit "brokerNotResponding"
        console.warn 'broker not responding'

      @broker.ping =>
        @unsuccessfulAttempt = 0
        clearTimeout timeout
        timeout = null


  changeBroker: ->
    # every time it will try to connect another broker, but here we are not
    # checking for the previous unsuccessful attempts
    @unsuccessfulAttempt = 0
    @broker.disconnect no
    brokerURL = @broker.sockURL.replace("/subscribe", "")
    @broker.selectAndConnect [brokerURL]
    # log while changing and send alert
    KD.logToExternal "broker connection error", broker : brokerURL


  recover: (callback) ->
    @once "brokerConnected", callback

    @changeBroker()