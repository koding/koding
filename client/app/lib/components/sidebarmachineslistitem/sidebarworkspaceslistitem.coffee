kd                      = require 'kd'
Link                    = require 'app/components/common/link'
React                   = require 'kd-react'
actions                 = require 'app/flux/environment/actions'
ReactDOM                = require 'react-dom'
getMachineLink          = require 'app/util/getMachineLink'
KDReactorMixin          = require 'app/flux/base/reactormixin'
EnvironmentFlux         = require 'app/flux/environment'
DeleteWorkspaceWidget   = require './deleteworkspacewidget'
getBoundingClientReact  = require 'app/util/getBoundingClientReact'
environmentDataProvider = require 'app/userenvironmentdataprovider'


module.exports = class SidebarWorkspacesListItem extends React.Component

  constructor: ->

    @state =
      coordinates = {}


  getDataBindings: ->
    activeWorkspace : EnvironmentFlux.getters.activeWorkspace


  componentWillReceiveProps: ->

    coordinates = getBoundingClientReact @refs.WorkspaceItem
    @setState { coordinates: coordinates }


  getWorkspaceLink: ->

    getMachineLink @props.machine, @props.workspace


  handleDeleteWorkspaceClick: (options) ->

    { machine } = options

    actions.deleteWorkspace(options).then =>
      kd.singletons.router.handleRoute "/IDE/#{machine.get 'machineLabel'}/my-workspace"


  handleWorkspaceSettingsClick: ->

    actions.showDeleteWorkspaceWidget @props.workspace.get '_id'


  handleDeleteWorkspaceOnClose: ->

    actions.hideDeleteWorkspaceWidget @props.workspace.get '_id'


  renderDeleteWorkspaceWidget: ->
    <DeleteWorkspaceWidget
      machine={@props.machine}
      workspace={@props.workspace}
      handleDeleteWorkspaceClick={@bound 'handleDeleteWorkspaceClick'}
      onClose={@bound 'handleDeleteWorkspaceOnClose'}
      coordinates={@state.coordinates}
      />


  handleLinkClick: ->

    actions.setSelectedWorkspaceId @props.workspace.get '_id'


  renderWorkspaceSettingsIcon: ->

    return null  if @props.workspace.get 'isDefault'

    <cite
      className='Workspace-settings'
      onClick={@bound 'handleWorkspaceSettingsClick'}
      />


  render: ->

    active = if @state.activeWorkspace is @props.workspace.get('_id')
    then 'active'
    else ''

    <div
      key={@props.workspace.get '_id'}
      ref='WorkspaceItem'
      className="Workspace-item #{active}">
      <cite className='Workspace-icon' />
      <Link className='Workspace-link' href={@getWorkspaceLink()} onClick={@bound 'handleLinkClick'}>
        <span className='Workspace-title'>{@props.workspace.get 'name'}</span>
      </Link>
      {@renderWorkspaceSettingsIcon()}
      {@renderDeleteWorkspaceWidget()}
    </div>

React.Component.include.call SidebarWorkspacesListItem, [KDReactorMixin]
