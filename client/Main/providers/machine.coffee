class Machine extends KDObject

  @State = {

    "NotInitialized"  # Initial state, machine instance does not exists
    "Building"        # Build started machine instance creating...
    "Starting"        # Machine is booting...
    "Running"         # Machine is physically running
    "Stopping"        # Machine is turning off...
    "Stopped"         # Machine is turned off
    "Rebooting"       # Machine is rebooting...
    "Terminating"     # Machine is getting destroyed...
    "Terminated"      # Machine is destroyed, not exists anymore
    "Unknown"         # Machine is in an unknown state
                      # needs to solved manually
  }


  constructor: (options = {})->

    { machine } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      throw new Error 'Data should be a JMachine instance'

    delete options.machine
    super options, machine

    { @label, @publicAddress, @_id, @provisioners
      @status, @uid, @queryString } = @jMachine = @getData()

    if @queryString?

      @kites   =
        klient : KD.singletons.kontrol.getKite {
          @queryString, correlationName: @uid
        }

    else
      @kites = {}

    @fs =
      # TODO: add options check
      create : (options, callback)=>
        options.machine = this
        FSItem.create options, callback

  getName: ->
    @label or @publicAddress or @uid or "one of #{KD.nick()}'s machine"

  getBaseKite: ->
    return @kites.klient  if @kites.klient?
    return {
      init : -> Promise.reject()
    }
