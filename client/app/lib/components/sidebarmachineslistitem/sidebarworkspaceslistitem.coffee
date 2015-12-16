kd                      = require 'kd'
Link                    = require 'app/components/common/link'
React                   = require 'kd-react'
actions                 = require 'app/flux/environment/actions'
getMachineLink          = require 'app/util/getMachineLink'
KDReactorMixin          = require 'app/flux/base/reactormixin'
EnvironmentFlux         = require 'app/flux/environment'
DeleteWorkspaceWidget   = require './deleteworkspacewidget'


module.exports = class SidebarWorkspacesListItem extends React.Component

  constructor: ->

    @state =
      coordinates = {}


  getDataBindings: ->
    activeWorkspace : EnvironmentFlux.getters.activeWorkspace


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

    active = if @state.activeWorkspace is @props.workspace.get('_id')
    then 'active'
    else ''

    <div
      key={@props.workspace.get '_id'}
      className="Workspace-item #{active}">
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

React.Component.include.call SidebarWorkspacesListItem, [KDReactorMixin]