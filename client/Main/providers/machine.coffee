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

    { machine, stack } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      throw new Error 'Data should be a JMachine instance'

    delete options.machine
    delete options.stack

    super options, machine

    @stack    = stack
    @jMachine = @getData()
    @updateLocalData()

    @fs =
      # TODO: add options check
      create : (options, callback)=>
        options.machine = this
        FSItem.create options, callback

    KD.singletons.computeController.on "public-#{machine._id}", (event)=>

      unless event.status is @jMachine.status.state

        @jMachine.setAt? "status.state", event.status
        @updateLocalData()


  updateLocalData:->
    { @label, @ipAddress, @_id, @provisioners, @provider
      @status, @uid, @domain, @queryString } = @jMachine

  getName: ->
    @label or @ipAddress or @uid or "one of #{KD.nick()}'s machine"


  getBaseKite: (createIfNotExists = yes)->

    { kontrol } = KD.singletons

    klient = kontrol.kites?.klient?[@uid]
    return klient  if klient

    if createIfNotExists and KD.utils.doesQueryStringValid @queryString

      kontrol.getKite { name: "klient", @queryString, correlationName: @uid }

    else

      {
        init       : -> Promise.reject()
        connect    : noop
        disconnect : noop
      }
