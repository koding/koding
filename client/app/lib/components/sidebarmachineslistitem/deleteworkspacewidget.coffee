React           = require 'kd-react'
Popover         = require 'app/components/common/popover'
actions         = require 'app/flux/environment/actions'
SidebarWidget   = require '../sidebarmachineslistitem/sidebarwidget'
KDReactorMixin  = require 'app/flux/base/reactormixin'
EnvironmentFlux = require 'app/flux/environment'


module.exports = class DeleteWorkspaceWidget extends React.Component

  @defaultProps =
    className : '--DeleteWorkspace'


  getDataBindings: ->
    deleteWorkspaceWidget : EnvironmentFlux.getters.deleteWorkspaceWidget


  handleButtonClick: ->

    options =
      machine            : @props.machine
      workspace          : @props.workspace
      deleteRelatedFiles : no

    @props.handleDeleteWorkspaceClick options


  render: ->

    return null  unless @state.deleteWorkspaceWidget is @props.workspace.get('_id')

    <SidebarWidget {...@props}>
      <div className='DeleteWorkspace-Guide'>
        <label>Related Guides</label>
        <a
          href=''
          title='Understanding Workspaces'
          className='DeleteWorkspace-Understading'>
          Understanding Workspaces
        </a>
      </div>

      <button
        className='kdbutton solid compact red DeleteWorkspace-Button'
        onClick={@bound 'handleButtonClick'}
        >
        <span className='button-title'>DELETE WORKSPACE</span>
      </button>

    </SidebarWidget>

React.Component.include.call DeleteWorkspaceWidget, [KDReactorMixin]
