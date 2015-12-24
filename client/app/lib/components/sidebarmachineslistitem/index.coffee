kd                             = require 'kd'
Link                           = require 'app/components/common/link'
React                          = require 'kd-react'
ReactDOM                       = require 'react-dom'
remote                         = require('app/remote').getInstance()
actions                        = require 'app/flux/environment/actions'
Machine                        = require 'app/providers/machine'
UnreadCount                    = require './unreadcount'
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
SharingMachineInvitationWidget = require './sharingmachineinvitationwidget'

module.exports = class SidebarMachinesListItem extends React.Component

  @defaultProps =
    showInSidebar                : yes
    bindWorkspacesTitleClick     : yes
    activeLeavingSharedMachineId : null


  getDataBindings: ->
    activeMachine : EnvironmentFlux.getters.activeMachine


  constructor: (props) ->

    super

    status = @machine ['status', 'state']

    @state = {
      collapsed : status isnt Machine.State.Running
      showLeaveSharedMachineWidget : no
    }


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


  handleMachineClick: (event) ->

    kd.utils.defer =>
      actions.setActiveInvitationMachineId { machine: @props.machine }
      actions.setActiveLeavingSharedMachineId null

    @setState { collapsed: not @state.collapsed }

    unless isMachineRunning @props.machine
      kd.singletons.router.handleRoute getMachineLink @props.machine


  renderProgressbar: ->

    status     = @machine ['status', 'state']
    percentage = @machine('percentage') or 0
    percentage = 100 - percentage  if status is Machine.State.Stopping
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

    <Link
      className='MachineSettings'
      onClick={@bound 'handleMachineSettingsClick'}
      />


  handleMachineSettingsClick: (event) ->

    kd.utils.stopDOMEvent event

    if @machine('type') is 'own'
      kd.singletons.router.handleRoute "/Machines/#{@machine 'slug'}"
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

    label  = "#{@machine 'label'}"
    label += " (@#{@machine 'owner'})"  if @machine('type') isnt 'own'

    return label


  createAddWorkspaceView: ->

    actions.showAddWorkspaceView @machine '_id'


  renderConnectedManagedMachineWidget: ->

    return null  unless @machine('provider') is 'managed'

    <ConnectedManagedMachineWidget
      machine={@props.machine}
      coordinates={@state.coordinates}
      />


  getTotalUnreadCount: ->

    totalCount = 0

    @machine('workspaces').toList().map (workspace) ->
      totalCount += (workspace.getIn(['channel', 'unreadCount'])) or 0

    return totalCount


  renderUnreadCount: ->

    return null  unless @state.collapsed

    <UnreadCount count={@getTotalUnreadCount()} />


  render: ->

    return null  unless @props.showInSidebar

    status      = @machine ['status', 'state']
    activeClass = if @state.activeMachine is @machine('_id') then ' active' else ''

    unread = if @getTotalUnreadCount() and @state.collapsed
    then 'unread'
    else ''

    <div className="SidebarMachinesListItem #{status} #{activeClass} #{unread}">
      <Link
        className="SidebarMachinesListItem--MainLink"
        href='#'
        onClick={@bound 'handleMachineClick'}
        ref='sidebarMachinesListItem'
        >
        <cite className={"SidebarListItem-icon"} title={"Machine status: #{status}"}/>
        <span className='SidebarListItem-title'>{@getMachineLabel()}</span>
        {@renderUnreadCount()}
        {@renderProgressbar()}
      </Link>
      {@renderMachineSettingsIcon()}
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

    status  = @machine ['status', 'state']
    users   = (@machine 'users').toJS()
    isOwner = yes for user in users when user.owner

    return  unless isOwner
    return  unless status is Machine.State.Running

    workspaces = []
    @props.machine.get('workspaces').map (ws) ->
      workspaces.push remote.revive ws.toJS()
    modal = new MoreWorkspacesModal {}, workspaces

    # TODO: handle new workspace creation
    modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceView'

React.Component.include.call SidebarMachinesListItem, [KDReactorMixin]


