kd                = require 'kd'
React             = require 'kd-react'
ReactDOM          = require 'react-dom'
Link              = require 'app/components/common/link'
KeyboardKeys      = require 'app/util/keyboardKeys'
IDEHelpers        = require 'ide/idehelpers'
EnvironmentFlux   = require 'app/flux/environment'
KDReactorMixin    = require 'app/flux/base/reactormixin'
actions           = require 'app/flux/environment/actions'


module.exports = class AddWorkspaceView extends React.Component

  { ESC, ENTER } = KeyboardKeys


  getDataBindings: ->
    addWorkspaceView : EnvironmentFlux.getters.addWorkspaceView


  componentDidUpdate: ->

    textInput = ReactDOM.findDOMNode @refs.WorkspaceAdd
    textInput?.focus()


  onKeyDown: (event) ->

    switch event.which
      when ENTER  then @onEnter event
      when ESC    then @onEsc()


  onEnter: (event) ->

    options =
      name          : event.target.value
      machineUId    : @props.machine.get 'uid'
      machineLabel  : @props.machine.get 'label'

    IDEHelpers.createWorkspace options


  onEsc: ->

    actions.hideAddWorkspaceView @props.machine.get '_id'


  onClick: (event) ->

    kd.utils.stopDOMEvent event


  render: ->

    return null  unless @state.addWorkspaceView.has @props.machine.get '_id'

    <div
      onClick={@bound 'onClick'}
      className='Workspace-link Workspace-add'
      >
      <cite className='Workspace-icon' />
      <input
        type='text'
        className='kdinput text'
        ref='WorkspaceAdd'
        onKeyDown={@bound 'onKeyDown'} />
      <cite className='Workspace-cancel' onClick={@bound 'onEsc'} />
    </div>


React.Component.include.call AddWorkspaceView, [KDReactorMixin]
