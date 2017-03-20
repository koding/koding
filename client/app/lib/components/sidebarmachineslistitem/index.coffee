kd                             = require 'kd'
Link                           = require 'app/components/common/link'
React                          = require 'app/react'
ReactDOM                       = require 'react-dom'
remote                         = require 'app/remote'
actions                        = require 'app/flux/environment/actions'
getMachineLink                 = require 'app/util/getMachineLink'
KDReactorMixin                 = require 'app/flux/base/reactormixin'
EnvironmentFlux                = require 'app/flux/environment'
isMachineRunning               = require 'app/util/isMachineRunning'
getBoundingClientReact         = require 'app/util/getBoundingClientReact'
LeaveSharedMachineWidget       = require './leavesharedmachinewidget'
isMachineSettingsIconEnabled   = require 'app/util/isMachineSettingsIconEnabled'
ConnectedManagedMachineWidget  = require './connectedmanagedmachinewidget'
SharingMachineInvitationWidget = require 'app/components/sidebarmachineslistitem/sharingmachineinvitationwidget'


require './styl/sidebarmachineslistItem.styl'
require './styl/sidebarwidget.styl'


module.exports = class SidebarMachinesListItem extends React.Component

  @defaultProps =
    stack                        : null
    showInSidebar                : yes


  getDataBindings: ->
    activeMachine : EnvironmentFlux.getters.activeMachine
    activeLeavingMachine : EnvironmentFlux.getters.activeLeavingSharedMachineId
    activeInvitationMachineId : EnvironmentFlux.getters.activeInvitationMachineId


  constructor: (props) ->

    super

    @state =
      percentage: 0
      status: @machine ['status', 'state']
      showLeaveSharedMachineWidget : no


  onComputeEvent: ({ percentage = 0, status }) ->

    @setState { percentage, status }


  componentDidMount: ->

    { computeController } = kd.singletons

    stackId = @props.stack.get '_id'
    machineId = @props.machine.get '_id'

    computeController.on "apply-#{stackId}", @bound 'onComputeEvent'
    computeController.on "public-#{machineId}", @bound 'onComputeEvent'

    kd.utils.defer =>
      actions.setMachineListItem @machine('_id'), this


  componentWillUnmount: ->

    { computeController } = kd.singletons

    stackId = @props.stack.get '_id'
    machineId = @props.machine.get '_id'

    computeController.off "apply-#{stackId}", @bound 'onComputeEvent'
    computeController.off "public-#{machineId}", @bound 'onComputeEvent'


    kd.utils.defer =>
      actions.unsetMachineListItem @machine('_id'), this


  componentWillReceiveProps: ->

    return  unless @refs.sidebarMachinesListItem

    coordinates = getBoundingClientReact @refs.sidebarMachinesListItem
    @setState { coordinates: coordinates }


  machine: (key) ->

    if typeof key is 'string'
    then @props.machine.get key
    else @props.machine.getIn key


  isOwner: ->

    users   = (@machine 'users').toJS()
    isOwner = yes for user in users when user.owner

    return !!isOwner


  handleMachineClick: (event) ->

    kd.utils.defer =>
      actions.setActiveInvitationMachineId { machine: @props.machine }
      actions.setActiveLeavingSharedMachineId null

    return  unless @props.machine.get 'isApproved'

    kd.singletons.router.handleRoute getMachineLink @props.machine


  renderProgressbar: ->

    { percentage, status } = @state
    { NotInitialized, Running, Stopped } = remote.api.JMachine.State

    return null  if status in [NotInitialized, Stopped]
    return null  if status is Running and percentage is 100

    fullClass  = if percentage is 100 then ' full' else ''

    <div className={"SidebarListItem-progressbar#{fullClass}"}>
      <cite style={width: "#{percentage}%"} />
    </div>


  renderLeaveSharedMachine: ->

    return null  if @machine('type') is 'own' or @machine 'hasOldOwner'
    return null  if @state.activeMachine isnt @machine('_id')
    return null  unless @machine 'isApproved'
    return null  unless @state.activeLeavingMachine

    <LeaveSharedMachineWidget
      coordinates={@state.coordinates}
      machine={@props.machine} />


  renderMachineSettingsIcon: ->

    return null  unless @machine 'isApproved'
    return null  unless @settingsEnabled()

    <span
      className='MachineSettings'
      onClick={@bound 'handleMachineSettingsClick'}>
    </span>


  handleMachineSettingsClick: (event) ->

    kd.utils.stopDOMEvent event

    if @machine('type') is 'own' or @machine 'hasOldOwner'
      kd.singletons.router.handleRoute "/Home/stacks/virtual-machines/#{@machine('_id')}"
    else
      sidebarListItem = ReactDOM.findDOMNode @refs.sidebarMachinesListItem
      clientRect      = sidebarListItem.getBoundingClientRect()
      coordinates     =
        top           : clientRect.top
        left          : clientRect.width + clientRect.left

      @setState { coordinates: coordinates}

      actions.setActiveInvitationMachineId { machine: @props.machine }
      actions.setActiveLeavingSharedMachineId @machine('_id')


  settingsEnabled: -> isMachineSettingsIconEnabled @props.machine.toJS()


  getMachineLabel: ->

    owner  = ""

    owner  = " (@#{@machine 'owner'})"  if @machine('type') in ['shared', 'collaboration']
    owner  = " (@#{@machine ['meta', 'oldOwner']})"  if @machine('type') is 'reassigned'

    return "#{@machine 'label'}#{owner}"


  renderConnectedManagedMachineWidget: ->

    return null  unless @machine('provider') is 'managed'

    <ConnectedManagedMachineWidget
      machine={@props.machine}
      coordinates={@state.coordinates}
      />


  renderInvitationWidget: ->

    return null  unless @state.coordinates
    return null  unless @props.machine.get('_id') is @state.activeInvitationMachineId

    <SharingMachineInvitationWidget
      key="InvitationWidget-#{@props.machine.get '_id'}"
      coordinates={@state.coordinates}
      machine={@props.machine} />


  render: ->

    return null  unless @props.showInSidebar

    { status }  = @state
    activeClass = ''

    if @state.activeMachine is @machine('_id')
      activeClass = 'active'

    <div className="SidebarMachinesListItem #{status} #{activeClass}">
      <Link
        className="SidebarMachinesListItem--MainLink"
        href='#'
        onClick={@bound 'handleMachineClick'}
        ref='sidebarMachinesListItem'
        >
        <cite className={"SidebarListItem-icon"} title={"Machine status: #{status}"}/>
        <span className='SidebarListItem-title'>{@getMachineLabel()}</span>
        {@renderProgressbar()}
        {@renderMachineSettingsIcon()}
      </Link>
      {@renderLeaveSharedMachine()}
      {@renderInvitationWidget()}
      {@renderConnectedManagedMachineWidget()}
    </div>


React.Component.include.call SidebarMachinesListItem, [KDReactorMixin]
