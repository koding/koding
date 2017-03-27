kd = require 'kd'
KDObject = kd.Object
globals = require 'globals'

module.exports = class ComputeStateChecker extends KDObject

  constructor: (options = {}) ->

    options.interval ?= 10000

    super options

    @ignoredMachines = []
    @tickInProgress  = no
    @running         = no
    @timer           = null

    @setStorage()

    kd.singletons.windowController.addFocusListener (state) =>
      if state then @start() else @stop()


  setStorage: (storage) ->

    storage ?= @getOption 'storage'
    @storage = storage  if storage


  start: ->

    return  if @running
    @running = yes

    @tick yes
    @timer = kd.utils.repeat @getOption('interval'), @bound 'tick'


  stop: ->

    return  unless @running
    @running = no

    kd.utils.killWait @timer


  ignore: (machineId) ->

    unless machineId in @ignoredMachines
      @ignoredMachines.push machineId


  watch: (machineId) ->

    @ignoredMachines = (m for m in @ignoredMachines when m isnt machineId)


  tick: (checkAll = no) ->

    machines = @storage.machines.get()

    return  unless machines.length
    return  if @tickInProgress
    @tickInProgress = yes

    { computeController, kontrol } = kd.singletons

    # kd.info "Checking all machine states..."  if checkAll

    machines.forEach (machine) =>

      machineId = machine._id
      currentState = machine.status.state

      if machineId in @ignoredMachines
        return

      if not machine.isRunning() and not machine.isManaged()
        return  if not checkAll
      else
        { klient }   = kontrol.kites
        machineUid = (computeController.findMachineFromMachineId machineId)?.uid
        if not (machineUid? and klient? and klient[machineUid])
          # Managed VMs needs to be checked even there is no klient kite
          # instance available for them. Kontrol instance will create a new
          # one if it's not exists. ~ GG
          return  unless machine.provider is 'managed'

      computeController.getKloud().info { machineId, currentState }

      .then (response) =>

        return  if machineId in @ignoredMachines

        computeController.eventListener
          .triggerState machine, { status: response.State }

        computeController.eventListener.followUpcomingEvents {
          _id    : machineId
          status : { state: response.State }
        }

        unless machine.status.state is response.State
          kd.info "csc: machine (#{machineId}) state changed: ", response.State
          computeController.triggerReviveFor machineId

        return response

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) ->

        # Ignore pending event and timeout errors but log others
        unless (err?.code in ['107', '500']) or (err?.name is 'TimeoutError')
          kd.log 'csc: info error happened:', err

    @tickInProgress = no
