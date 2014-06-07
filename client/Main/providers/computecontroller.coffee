class ComputeController extends KDController

  @providers = KD.config.providers

  constructor:->
    super

    { mainController, kontrol } = KD.singletons

    mainController.ready =>

      @kloud         = kontrol.getKite
        name         : "kloud"
        environment  : "vagrant"

      @eventListener = new ComputeEventListener

      @on "machineBuildCompleted", => delete @stacks


  fetchStacks: (callback = noop)->

    if @stacks
      callback null, @stacks
      info "Stacks returned from cache."
      return

    KD.remote.api.JStack.some {}, (err, stacks = [])=>
      return callback err  if err?
      callback null, @stacks = stacks


  fetchMachines: (callback)->

    @fetchStacks (err, stacks)->
      return callback err  if err?

      machines = []
      stacks.forEach (stack)->
        stack.machines.forEach (machine)->
          machines.push new Machine { machine }

      callback null, machines


  credentialsFor: (provider, callback)->
    KD.remote.api.JCredential.some { provider }, callback

  fetchAvailable: (options, callback)->
    KD.remote.api.ComputeProvider.fetchAvailable options, callback

  fetchExisting: (options, callback)->
    KD.remote.api.ComputeProvider.fetchExisting options, callback

  create: (options, callback)->
    KD.remote.api.ComputeProvider.create options, callback

  createDefaultStack: ->

    KD.remote.api.ComputeProvider.createGroupStack (err, stack)=>
      return if KD.showError err

      delete @stacks
      @emit "renderStacks"

  destroy: (machine)->

    ComputeController.UI.askFor 'destroy', machine, =>

      @kloud.destroy { machineId: machine._id }

      .then (res)=>

        @eventListener.addListener 'destroy', machine._id
        log "destroy res:", res

      .catch (err)->
        warn "destroy err:", err


  build: (machine)->

    @kloud.build { machineId: machine._id }

    .then (res)=>

      @eventListener.addListener 'build', machine._id
      log "build res:", res

    .catch (err)->
      warn "build err:", err


  info: (machine)->

    log "[info]", machine

    # If machine state is NotInitialized or Terminated
    # we don't need to ask info to kloud kite.
    { NotInitialized, Terminated, Building } = Machine.State
    if machine.status.state in [ NotInitialized, Terminated ]
      @emit "public-#{machine._id}", { status: machine.status.state }
      return Promise.resolve()

    if machine.status.state is Building
      log "state is building, start polling"
      @eventListener.addListener 'build', machine._id
      return Promise.resolve()


    @kloud.info { machineId: machine._id }

    .then (res)=>

      log "info res:", res
      @emit "public-#{machine._id}", { status: res.State }

    .catch (err)->
      warn "info err:", err

