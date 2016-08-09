kd                             = require 'kd'
Link                           = require 'app/components/common/link'
React                          = require 'kd-react'
ReactDOM                       = require 'react-dom'
remote                         = require('app/remote').getInstance()
actions                        = require 'app/flux/environment/actions'
Machine                        = require 'app/providers/machine'
isKoding                       = require 'app/util/isKoding'
getMachineLink                 = require 'app/util/getMachineLink'
KDReactorMixin                 = require 'app/flux/base/reactormixin'
EnvironmentFlux                = require 'app/flux/environment'
AddWorkspaceView               = require './addworkspaceview'
isMachineRunning               = require 'app/util/isMachineRunning'
MoreWorkspacesModal            = require 'app/activity/sidebar/moreworkspacesmodal'
getBoundingClientReact         = require 'app/util/getBoundingClientReact'
LeaveSharedMachineWidget       = require './leavesharedmachinewidget'
SidebarWorkspacesListItem      = require './sidebarworkspaceslistitem'
isMachineSettingsIconEnabled   = require 'app/util/isMachineSettingsIconEnabled'
ConnectedManagedMachineWidget  = require './connectedmanagedmachinewidget'

require './styl/sidebarmachineslistItem.styl'
require './styl/sidebarwidget.styl'


module.exports = class SidebarMachinesListItem extends React.Component

  @defaultProps =
    stack                        : null
    showInSidebar                : yes
    bindWorkspacesTitleClick     : yes
    activeLeavingSharedMachineId : null


  getDataBindings: ->
    activeMachine : EnvironmentFlux.getters.activeMachine


  constructor: (props) ->

    super

    status = @machine ['status', 'state']

    collapsed = if isKoding() then status isnt Machine.State.Running else yes

    @state = {
      collapsed
      showLeaveSharedMachineWidget : no
    }

    @listenMachineEvents()


  listenMachineEvents: ->

    machineId             = @machine('_id')
    { computeController } = kd.singletons

    computeController.on "start-#{machineId}", (event) =>
      @setState { collapsed: no }  if event.percentage is 100

    computeController.on "stop-#{machineId}", (event) =>
      @setState { collapsed : yes }  unless event.percentage

    if stackId = @props.stack?.get('_id')
      computeController.on "apply-#{stackId}", (event) =>
        { percentage, message } = event
        if percentage is 100 and message in [ 'apply finished', 'reinit finished' ]
          @setState { collapsed: no }


  componentWillReceiveProps: ->

    return  unless @refs.sidebarMachinesListItem

    coordinates = getBoundingClientReact @refs.sidebarMachinesListItem
    @setState { coordinates: coordinates }


  componentDidMount: ->

    kd.utils.defer =>
      actions.setMachineListItem @machine('_id'), this


  componentWillUnmount: ->

    kd.utils.defer =>
      actions.unsetMachineListItem @machine('_id'), this


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

    @setState { collapsed : not @state.collapsed }  if isKoding()

    return  unless @props.machine.get 'isApproved'

    if not isMachineRunning(@props.machine) or not isKoding()
      kd.singletons.router.handleRoute getMachineLink @props.machine


  renderProgressbar: ->

    status     = @machine ['status', 'state']
    percentage = @machine('percentage') or 0

    return null  if status in [Machine.State.NotInitialized, Machine.State.Stopped]
    return null  if status is Machine.State.Running and percentage is 100

    fullClass  = if percentage is 100 then ' full' else ''

    <div className={"SidebarListItem-progressbar#{fullClass}"}>
      <cite style={width: "#{percentage}%"} />
    </div>


  renderWorkspaces: ->

    @machine('workspaces').toList().map (workspace) =>
      <SidebarWorkspacesListItem
        key={workspace.get '_id'}
        machine={@props.machine}
        workspace={workspace}
        />


  renderWorkspaceSection: ->

    return null  unless isKoding()
    return null  if @state.collapsed
    return null  unless @machine 'isApproved'
    return null  unless isMachineRunning @props.machine

    <section className='Workspaces-section'>
      <h3 onClick={@bound 'handleWorkspacesTitleClick'}>WORKSPACES</h3>
      {@renderWorkspaces()}
      {@renderAddWorkspaceView()}
    </section>


  renderAddWorkspaceView: ->
    <AddWorkspaceView
      machine={@props.machine}
      />


  renderLeaveSharedMachine: ->

    return null  if @props.activeLeavingSharedMachineId isnt @machine('_id')
    return null  if @machine('type') is 'own'
    return null  unless @machine 'isApproved'

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
      kd.singletons.router.handleRoute "/Home/Stacks/virtual-machines/#{@machine 'label'}"
    else
      sidebarListItem = ReactDOM.findDOMNode @refs.sidebarMachinesListItem
      clientRect      = sidebarListItem.getBoundingClientRect()
      coordinates     =
        top           : clientRect.top - 15
        left          : clientRect.width + clientRect.left + 15

      @setState { coordinates: coordinates}

      actions.setActiveInvitationMachineId { machine: @props.machine }
      actions.setActiveLeavingSharedMachineId @machine('_id')


  settingsEnabled: -> isMachineSettingsIconEnabled @props.machine.toJS()


  getMachineLabel: ->

    owner  = ""

    owner  = " (@#{@machine 'owner'})"  if @machine('type') in ['shared', 'collaboration']
    owner  = " (@#{@machine ['meta', 'oldOwner']})"  if @machine('type') is 'reassigned'

    return "#{@machine 'label'}#{owner}"


  createAddWorkspaceView: ->

    id = @machine '_id'

    actions.hideAddWorkspaceView id # Before hide it if it's visible
    actions.showAddWorkspaceView id # After show it


  renderConnectedManagedMachineWidget: ->

    return null  unless @machine('provider') is 'managed'

    <ConnectedManagedMachineWidget
      machine={@props.machine}
      coordinates={@state.coordinates}
      />


  render: ->

    return null  unless @props.showInSidebar

    status      = @machine ['status', 'state']
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
      {@renderWorkspaceSection()}
      {@renderLeaveSharedMachine()}
      {@renderConnectedManagedMachineWidget()}
    </div>


  #
  # LEGACY METHODS
  #

  handleWorkspacesTitleClick: (event) ->

    return null  unless @machine('type') is 'own'

    { computeController } = kd.singletons

    return  unless @isOwner()

    status = @machine ['status', 'state']
    return  unless status is Machine.State.Running

    workspaces = []
    @props.machine.get('workspaces').map (ws) ->
      workspaces.push remote.revive ws.toJS()
    modal = new MoreWorkspacesModal {}, workspaces

    # TODO: handle new workspace creation
    modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceView'

React.Component.include.call SidebarMachinesListItem, [KDReactorMixin]


