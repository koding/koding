class Machine extends KDObject


  constructor: (options = {})->

    { machine } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      throw new Error 'Data should be a JMachine instance'

    delete options.machine
    super options, machine

    { @label, @publicAddress, @_id
      @status, @uid, @queryString } = @jMachine = @getData()

    if @queryString?
      @kites   =
        klient : KD.singletons.kontrolProd.getKite {
          @queryString, correlationName: @uid
        }

    else
      @kites = {}


  getName: ->
    @publicAddress or @uid or @label or "one of #{KD.nick()}'s machine"

