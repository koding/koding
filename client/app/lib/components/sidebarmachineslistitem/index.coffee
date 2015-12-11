kd                              = require 'kd'
Link                            = require 'app/components/common/link'
React                           = require 'kd-react'
remote                          = require('app/remote').getInstance()
Machine                         = require 'app/providers/machine'
ReactDOM                        = require 'react-dom'
htmlencode                      = require 'htmlencode'
toImmutable                     = require 'app/util/toImmutable'
getMachineLink                  = require 'app/util/getMachineLink'
isMachineRunning                = require 'app/util/isMachineRunning'
MoreWorkspacesModal             = require 'app/activity/sidebar/moreworkspacesmodal'
LeaveSharedMachineWidget        = require './leavesharedmachinewidget'
isMachineSettingsIconEnabled    = require 'app/util/isMachineSettingsIconEnabled'
SharingMachineInvitationWidget  = require './sharingmachineinvitationwidget'


module.exports = class SidebarMachinesListItem extends React.Component

  @defaultProps =
    bindWorkspacesTitleClick  : yes


  constructor: (props) ->

    super

    status = @machine ['status', 'state']

    @state = {
      collapsed : status isnt Machine.State.Running and not @props.active
      showLeaveSharedMachineWidget : yes
    }


  componentWillReceiveProps: ->

    sidebarListItem = ReactDOM.findDOMNode @refs.SidebarMachinesListItem
    clientRect      = sidebarListItem.getBoundingClientRect()
    coordinates     =
      top           : clientRect.top - 15
      left          : clientRect.width + clientRect.left + 15

    @setState { coordinates: coordinates }


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
      <Link
        key={workspace.get '_id'}
        className='Workspace-link'
        href={@getWorkspaceLink workspace}
        >
        <cite className='Workspace-icon' />
        <span className='Workspace-title'>{workspace.get 'name'}</span>
      </Link>


  getWorkspaceLink: (workspace) ->

    getMachineLink @props.machine, workspace


  renderWorkspaceSection: ->

    return null  if @state.collapsed
    return null  unless @machine 'isApproved'
    return null  unless isMachineRunning @props.machine

    <section className='Workspaces-section'>
      <h3 onClick={@bound 'handleWorkspacesTitleClick'}>WORKSPACES</h3>
      {@renderWorkspaces()}
    </section>


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


  render: ->

    status      = @machine ['status', 'state']
    activeClass = if @props.active then ' active' else ''

    <div className="SidebarMachinesListItem #{status}">
      <Link
        className={"SidebarMachinesListItem--MainLink#{activeClass}"}
        # make this link dynamic pointing to latest open workspace
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
    </div>


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
    # modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceInput'


