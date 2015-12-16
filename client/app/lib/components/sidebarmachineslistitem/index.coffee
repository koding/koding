kd                             = require 'kd'
Link                           = require 'app/components/common/link'
React                          = require 'kd-react'
remote                         = require('app/remote').getInstance()
actions                        = require 'app/flux/environment/actions'
Machine                        = require 'app/providers/machine'
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
      collapsed : status isnt Machine.State.Running and not @props.active
      showLeaveSharedMachineWidget : yes
    }


  componentWillReceiveProps: ->

    return  unless @refs.SidebarMachinesListItem

    coordinates = getBoundingClientReact @refs.SidebarMachinesListItem
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

    kd.utils.stopDOMEvent event
    @setState { collapsed: not @state.collapsed }

    unless isMachineRunning @props.machine
      kd.singletons.router.handleRoute getMachineLink @props.machine


  renderUnreadCount: ->
    return null  unless @props.unreadCount > 0

    return \
      <cite className='SidebarListItem-unreadCount'>
        {@props.unreadCount}
      </cite>


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


  renderInvitationWidget: ->

    return null  if @machine('type') is 'own'
    return null  if @machine 'isApproved'

    <SharingMachineInvitationWidget
      coordinates={@state.coordinates}
      machine={@props.machine}
      />


  renderLeaveSharedMachine: ->

    return null  unless @state.showLeaveSharedMachineWidget
    return null  if @machine('type') is 'own'
    return null  unless @machine 'isApproved'

    <LeaveSharedMachineWidget
      coordinates={@state.coordinates}
      machine={@props.machine}
      isOpened={@state.showLeaveSharedMachineWidget}
      onClose={@bound 'handlePopoverOnClose'}
      />


  handlePopoverOnClose: ->

    @setState { showLeaveSharedMachineWidget : no }


  renderMachineSettingsIcon: ->

    return null  unless @machine 'isApproved'
    return null  unless @settingsEnabled()

    <Link
      className='MachineSettings'
      onClick={@bound 'handleMachineSettingsClick'}
      />


  handleMachineSettingsClick: ->

    if @machine('type') is 'own'
      kd.singletons.router.handleRoute "/Machines/#{@machine 'slug'}"
    else
      @setState { showLeaveSharedMachineWidget : yes }


  settingsEnabled: -> isMachineSettingsIconEnabled @props.machine.toJS()


  getMachineLabel: ->

    label  = "#{@machine 'label'}"
    label += " (@#{@machine 'owner'})"  if @machine('type') isnt 'own'

    return label


  createAddWorkspaceInput: ->

    actions.showAddWorkspaceView @machine '_id'


  renderConnectedManagedMachineWidget: ->

    return null  unless @machine('provider') is 'managed'

    <ConnectedManagedMachineWidget
      machine={@props.machine}
      coordinates={@state.coordinates}
      />


  render: ->

    return null  unless @props.showInSidebar

    status      = @machine ['status', 'state']
    activeClass = if @state.activeMachine is @machine('_id') then ' active' else ''

    <div className="SidebarMachinesListItem #{status} #{activeClass}">
      <Link
        className={"SidebarMachinesListItem--MainLink"}
        href='#'
        onClick={@bound 'handleMachineClick'}
        ref='SidebarMachinesListItem'
        >
        <cite className={"SidebarListItem-icon"} title={"Machine status: #{status}"}/>
        <span className='SidebarListItem-title'>{@getMachineLabel()}</span>
        {@renderUnreadCount()}
        {@renderProgressbar()}
      </Link>
      {@renderMachineSettingsIcon()}
      {@renderWorkspaceSection()}
      {@renderInvitationWidget()}
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
    modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceInput'

React.Component.include.call SidebarMachinesListItem, [KDReactorMixin]


