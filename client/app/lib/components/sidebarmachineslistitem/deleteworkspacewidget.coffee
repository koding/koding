kd              = require 'kd'
React           = require 'kd-react'
Popover         = require 'app/components/common/popover'
actions         = require 'app/flux/environment/actions'
SidebarWidget   = require '../sidebarmachineslistitem/sidebarwidget'
KDReactorMixin  = require 'app/flux/base/reactormixin'
EnvironmentFlux = require 'app/flux/environment'
Toggle          = require 'app/components/common/toggle'


module.exports = class DeleteWorkspaceWidget extends React.Component

  @defaultProps =
    className : 'DeleteWorkspace'


  constructor: (props) ->

    super props

    @state =
      deleteAllFiles : no


  getDataBindings: ->
    deleteWorkspaceWidget : EnvironmentFlux.getters.deleteWorkspaceWidget


  handleButtonClick: ->

    options =
      machine            : @props.machine
      workspace          : @props.workspace
      deleteRelatedFiles : @state.deleteAllFiles

    actions.deleteWorkspace(options).then =>
      kd.singletons.router.handleRoute "/IDE/#{@props.machine.get 'label'}/my-workspace"


  handleOnClose: ->

    kd.utils.defer =>
      actions.hideDeleteWorkspaceWidget @props.workspace.get '_id'


  handleDeleteAllFiles: (status) ->

    @setState { deleteAllFiles : status }


  render: ->

    return null  unless @state.deleteWorkspaceWidget is @props.workspace.get('_id')

    <SidebarWidget {...@props} onClose={@bound 'handleOnClose'}>
      <div className='DeleteWorkspace-Guide'>
        <label>Related Guides</label>
        <a
          title='Understanding Workspaces'
          className='DeleteWorkspace-Understading'
          href='https://koding.com/docs/getting-started-workspaces'>
          Understanding Workspaces
        </a>
      </div>

      <button
        className='kdbutton solid compact red DeleteWorkspace-Button'
        onClick={@bound 'handleButtonClick'}
        >
        <span className='button-title'>DELETE WORKSPACE</span>
      </button>

      <div className='DeleteWorkspace-Files'>
        also delete its files
        <Toggle size='tiny' callback={@bound 'handleDeleteAllFiles'} />
      </div>

    </SidebarWidget>

React.Component.include.call DeleteWorkspaceWidget, [KDReactorMixin]
