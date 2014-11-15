class ComputeStateChecker extends KDObject

  constructor:(options = {})->

    super
      interval : options.interval ? 10000

    @kloud           = KD.singletons.kontrol.getKite
      name           : "kloud"
      environment    : KD.config.environment

    @machines        = []
    @ignoredMachines = []
    @tickInProgress  = no
    @running         = no
    @timer           = null

    KD.singletons.windowController.addFocusListener (state)=>
      if state then @start() else @stop()

  start:->

    return  if @running
    @running = yes

    @tick yes
    @timer = KD.utils.repeat @getOption('interval'), @bound 'tick'


  stop:->

    return  unless @running
    @running = no

    KD.utils.killWait @timer


  addMachine:(machine)->

    for m in @machines
      return  if machine.uid is m.uid

    @machines.push machine


  ignore: (machineId)->

    unless machineId in @ignoredMachines
      @ignoredMachines.push machineId


  watch: (machineId)->

    @ignoredMachines = (m for m in @ignoredMachines when m isnt machineId)


  tick: (checkAll = no)->

    return  unless @machines.length
    return  if @tickInProgress
    @tickInProgress = yes

    {computeController, kontrol} = KD.singletons

    @machines.forEach (machine)=>

      machineId = machine._id
      currentState = machine.status.state

      if machineId in @ignoredMachines
        return

      unless currentState is Machine.State.Running
        return  if not checkAll
      else
        {klient}   = kontrol.kites
        machineUid = computeController.findUidFromMachineId machineId
        return  if not (machineUid? and klient? and klient[machineUid])

      info "Checking all machine states..."  if checkAll

      call = @kloud.info { machineId, currentState }

      .then (response)=>

        return  if machineId in @ignoredMachines

        computeController.eventListener
          .triggerState machine, status: response.State

        computeController.followUpcomingEvents
          _id: machineId, status: state: response.State

        unless machine.status.state is response.State
          info "csc: machine (#{machineId}) state changed: ", response.State
          computeController.triggerReviveFor machineId

      .timeout ComputeController.timeout

      .catch (err)->

        # Ignore pending event and timeout errors but log others
        unless (err?.code is "107") or (err?.name is "TimeoutError")
          log "csc: info error happened:", err

    @tickInProgress = no
