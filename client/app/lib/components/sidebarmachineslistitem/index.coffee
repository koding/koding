kd                  = require 'kd'
React               = require 'kd-react'
toImmutable         = require 'app/util/toImmutable'
Link                = require 'app/components/common/link'
Machine             = require 'app/providers/machine'
remote              = require('app/remote').getInstance()
MoreWorkspacesModal = require 'app/activity/sidebar/moreworkspacesmodal'

module.exports = class SidebarMachinesListItem extends React.Component

  constructor: (props) ->

    super

    status = @machine ['status', 'state']

    @state = {
      collapsed : status isnt Machine.State.Running and not @props.active
    }


  machine: (key) ->

    if typeof key is 'string'
    then @props.machine.get key
    else @props.machine.getIn key


  handleMachineClick: (event) ->

    kd.utils.stopDOMEvent event
    @setState { collapsed: not @state.collapsed }


  renderUnreadCount: ->
    return null  unless @props.unreadCount > 0

    return \
      <cite className='SidebarListItem-unreadCount'>
        {@props.unreadCount}
      </cite>


  renderProgressbar: ->
    status = @machine ['status', 'state']
    percentage = @machine('percentage') or 0
    percentage = 100 - percentage  if status is Machine.State.Stopping

    <div className={"SidebarListItem-progressbar#{if percentage is 100 then ' full' else ''}"}>
      <cite style={width: "#{percentage}%"} />
    </div>


  renderWorkspaces: ->

    @machine('workspaces').toList().map (workspace) =>
      <Link
        key={workspace.get '_id'}
        className='Workspace-link'
        href={"/IDE/#{@machine 'slug'}/#{workspace.get 'slug'}"}
        >
        <cite className='Workspace-icon' />
        <span className='Workspace-title'>{workspace.get 'name'}</span>
      </Link>


  renderWorkspaceSection: ->

    return null  if @state.collapsed

    <section className='Workspaces-section'>
      <h3 onClick={@bound 'handleWorkspacesTitleClick'}>WORKSPACES</h3>
      {@renderWorkspaces()}
    </section>


  render: ->

    status = @machine ['status', 'state']
    activeClass = if @props.active then ' active' else ''

    <div className="SidebarMachinesListItem #{status}">
      <Link
        className={"SidebarMachinesListItem--MainLink#{activeClass}"}
        # make this link dynamic pointing to latest open workspace
        href={"/IDE/#{@machine 'slug'}"}
        onClick={@bound 'handleMachineClick'}
        >
        <cite className={"SidebarListItem-icon"} title={"Machine status: #{status}"}/>
        <span className='SidebarListItem-title'>{@machine 'label'}</span>
        {@renderUnreadCount()}
        {@renderProgressbar()}
      </Link>
      <Link
        className='MachineSettings'
        href={"/Machines/#{@machine 'slug'}"}
        />
      {@renderWorkspaceSection()}
    </div>


  #
  # LEGACY METHODS
  #

  handleWorkspacesTitleClick: (event) ->

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


