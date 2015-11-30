kd          = require 'kd'
React       = require 'kd-react'
classnames  = require 'classnames'
toImmutable = require 'app/util/toImmutable'
Link        = require 'app/components/common/link'

module.exports = class SidebarMachinesListItem extends React.Component

  constructor: (props) ->

    super

    status = @props.machine.getIn ['status', 'state']

    @state = {
      collapsed : status isnt 'Running' and not @props.active
      status
    }


  machine: (key) ->

    if typeof key is 'string'
    then @props.machine.get key
    else @props.machine.getIn key


  getClassName: ->
    classnames
      SidebarListItem : yes
      active          : @props.active
      machine         : yes


  handleMachineClick: (event) ->

    kd.utils.stopDOMEvent event
    console.log @state.collapsed
    @setState { collapsed: not @state.collapsed }


  renderUnreadCount: ->
    return null  unless @props.unreadCount > 0

    return \
      <cite className='SidebarListItem-unreadCount'>
        {@props.unreadCount}
      </cite>


  renderProgressbar: ->

    <div className="SidebarListItem-progressbar" />


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
      <h3>WORKSPACES</h3>
      {@renderWorkspaces()}
    </section>


  render: ->

    status = @machine ['status', 'state']
    <div className="SidebarMachinesListItem #{status}">
      <Link
        className={@getClassName()}
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

