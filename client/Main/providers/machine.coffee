class Machine extends KDObject

  @State = {

    'NotInitialized'  # Initial state, machine instance does not exists
    'Building'        # Build started machine instance is being created...
    'Starting'        # Machine is booting...
    'Running'         # Machine is physically running
    'Stopping'        # Machine is turning off...
    'Stopped'         # Machine is turned off
    'Rebooting'       # Machine is rebooting...
    'Terminating'     # Machine is being destroyed...
    'Terminated'      # Machine is destroyed, does not exist anymore
    'Updating'        # Machine is being updated by provisioner
    'Unknown'         # Machine is in an unknown state
                      # needs to be resolved manually
  }


  constructor: (options = {})->

    { machine, stack } = options
    unless machine?.bongo_?.constructorName is 'JMachine'
      error 'Data should be a JMachine instance'
      # throw new Error 'Data should be a JMachine instance'

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

    {computeController} = KD.singletons

    computeController.on "public-#{machine._id}", (event)=>

      unless event.status is @jMachine.status.state

        @jMachine.setAt? "status.state", event.status
        @updateLocalData()

    computeController.on "revive-#{machine._id}", (machine)=>

      # update machine data
      @jMachine = machine
      @updateLocalData()


  updateLocalData:->
    { @label, @ipAddress, @_id, @provisioners, @provider
      @status, @uid, @domain, @queryString } = @jMachine
    @alwaysOn = @jMachine.meta.alwaysOn ? no

  getName: ->
    {uid, label, ipAddress} = this

    return label or ipAddress or uid or "one of #{KD.nick()}'s machines"


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
