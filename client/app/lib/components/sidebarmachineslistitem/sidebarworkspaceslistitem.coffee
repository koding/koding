kd                      = require 'kd'
Link                    = require 'app/components/common/link'
React                   = require 'kd-react'
actions                 = require 'app/flux/environment/actions'
getMachineLink          = require 'app/util/getMachineLink'
DeleteWorkspaceWidget   = require './deleteworkspacewidget'


module.exports = class SidebarWorkspacesListItem extends React.Component

  constructor: ->

    @state =
      coordinates = {}


  getWorkspaceLink: ->

    getMachineLink @props.machine, @props.workspace


  handleWorkspaceSettingsClick: ->

    # @setState { showDeleteWorkspaceWidget : yes }


  handleDeleteWorkspaceClick: (options) ->

    { machine } = options

    actions.deleteWorkspace(options).then =>
      # @setState { showDeleteWorkspaceWidget : no }
      kd.singletons.router.handleRoute "/IDE/#{machine.get 'machineLabel'}/my-workspace"


  renderDeleteWorkspaceWidget: ->

    <DeleteWorkspaceWidget
      machine={@props.machine}
      workspace={@props.workspace}
      coordinates={@state.coordinates}
      handleDeleteWorkspaceClick={@bound 'handleDeleteWorkspaceClick'}
      />


  handleLinkClick: ->

    actions.setSelectedWorkspaceId @props.workspace.get '_id'


  render: ->
    <div
      key={@props.workspace.get '_id'}
      className='Workspace-item'>
      <cite className='Workspace-icon' />
      <Link className='Workspace-link' href={@getWorkspaceLink()} onClick={@bound 'handleLinkClick'}>
        <span className='Workspace-title'>{@props.workspace.get 'name'}</span>
      </Link>
      <cite
        className='Workspace-settings'
        onClick={@bound 'handleWorkspaceSettingsClick'}
        />
      {@renderDeleteWorkspaceWidget()}
    </div>
