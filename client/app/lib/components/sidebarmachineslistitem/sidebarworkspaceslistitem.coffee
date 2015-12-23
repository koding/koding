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


  setCoordinates: ->

    coordinates = getBoundingClientReact @refs.workspaceItem
    @setState { coordinates: coordinates }


  componentWillReceiveProps: -> @setCoordinates()


  componentDidMount: -> @setCoordinates()


  getWorkspaceLink: ->

    getMachineLink @props.machine, @props.workspace


  handleWorkspaceSettingsClick: ->

    actions.showDeleteWorkspaceWidget @props.workspace.get '_id'


  renderDeleteWorkspaceWidget: ->
    <DeleteWorkspaceWidget
      machine={@props.machine}
      workspace={@props.workspace}
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
      ref='workspaceItem'
      className="Workspace-item #{active}">
      <cite className='Workspace-icon' />
      <Link className='Workspace-link' href={@getWorkspaceLink()} onClick={@bound 'handleLinkClick'}>
        <span className='Workspace-title'>{@props.workspace.get 'name'}</span>
      </Link>
      {@renderWorkspaceSettingsIcon()}
      {@renderDeleteWorkspaceWidget()}
    </div>

React.Component.include.call SidebarWorkspacesListItem, [KDReactorMixin]
