kd = require 'kd'
KDNotificationView = kd.NotificationView
ColorSelection = require './colorselection'
EnvironmentItem = require './environmentitem'
remote = require('app/remote').getInstance()
isGuest = require 'app/util/isGuest'
Machine = require 'app/providers/machine'
ComputeController = require 'app/providers/computecontroller'
MachineItem = require 'app/providers/machineitem'


module.exports = class EnvironmentMachineItem extends EnvironmentItem

  # TODO: move functionality to delegate ~ GG
  {warn} = kd

  stateClasses = ""
  for state in Object.keys Machine.State
    stateClasses += "#{state.toLowerCase()} "

  constructor:(options={}, data)->

    options.cssClass           = 'machine'
    options.joints             = ['left']

    options.allowedConnections =
      EnvironmentDomainItem    : ['right']

    super options, data

  viewAppended: ->

    machine = @getData()
    @addSubView @machineItem = new MachineItem {}, machine

    { computeController } = kd.singletons

    computeController.on "build-#{machine._id}",   @bound 'invalidateMachine'
    computeController.on "destroy-#{machine._id}", @bound 'invalidateMachine'


  invalidateMachine:(event)->

    if event.percentage is 100

      machine = @machineItem.getData()
      remote.api.JMachine.one machine._id, (err, newMachine)=>
        if err then warn ".>", err
        else
          @machineItem.setData new Machine machine: newMachine
          @machineItem.ipAddress.updatePartial @machineItem.getIpLink()

        if /^build/.test event.eventId
          kd.utils.wait 3000, =>
            new KDNotificationView
              title: "Preparing to run init script..."
            @runBuildScript()


  contextMenuItems: ->

    machine = @machineItem.getData()

    return if isGuest()

    buildReady = machine.status.state in [
      Machine.State.NotInitialized
      Machine.State.Terminated
    ]

    running  = machine.status.state is Machine.State.Running

    colorSelection = new ColorSelection selectedColor : @getOption 'colorTag'
    colorSelection.on "ColorChanged", @bound 'setColorTag'

    items =

      'Build Machine'     :
        disabled          : !buildReady
        callback          : ->
          {computeController} = kd.singletons
          computeController.build machine
          @destroy()

      'Update build script':
        callback          : ->
          ComputeController.UI.showBuildScriptEditorModal machine

      'Run build script'  :
        disabled          : !running
        separator         : yes

      'Launch Terminal'   :
        disabled          : !running
        callback          : @machineItem.lazyBound "openTerminal", {}
        separator         : yes

      'Delete'            :
        disabled          : isGuest()
        action            : 'delete'
        separator         : yes

      customView2         : colorSelection

    if running
      items['Run build script'].children =
        'Inside a terminal'     :
          callback              : ->
            ComputeController.runInitScript machine
        'As background process' :
          callback              : ->
            ComputeController.runInitScript machine, inTerminal = no

    return items


  confirmDestroy:->

    {computeController} = kd.singletons
    computeController.destroy @getData()
