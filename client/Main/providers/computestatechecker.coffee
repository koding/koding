class ComputeStateChecker extends KDObject

  constructor:(options = {})->

    super
      interval : options.interval ? 10000

    @kloud           = KD.singletons.kontrol.getKite
      name           : "kloud"
      environment    : KD.config.environment

    @machines        = []
    @machineStatuses = {}
    @tickInProgress  = no
    @running         = no
    @timer           = null

    KD.singletons.windowController.addFocusListener (state)=>
      if state then @start() else @stop()

  start:->

    return  if @running
    @running = yes

    info "ComputeState checker started."

    @tick()
    @timer = KD.utils.repeat @getOption('interval'), @bound 'tick'


  stop:->

    return  unless @running
    @running = no

    info "ComputeState checker stopped."

    KD.utils.killWait @timer


  addMachine:(machine)->

    for m in @machines
      return  if machine.uid is m.uid

    @machines.push machine


  tick:->

    return  unless @machines.length
    return  if @tickInProgress
    @tickInProgress = yes

    {computeController} = KD.singletons

    @machines.forEach (machine)=>

      call = @kloud.info { machineId: machine._id }

      .then (response)=>

        computeController.eventListener
          .triggerState machine, status : response.State

        computeController.followUpcomingEvents {
          _id: machine._id, status: state: response.State
        }

        unless machine.status.state is response.State
          computeController.triggerReviveFor machine._id

      .timeout ComputeController.timeout

      .catch (err)=>

        # Ignore pending event and timeout errors but log others
        unless (err?.code is "107") or (err?.name is "TimeoutError")
          log "csc: info error happened:", err

    @tickInProgress = no
