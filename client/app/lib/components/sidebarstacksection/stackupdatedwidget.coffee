kd = require 'kd'
React         = require 'kd-react'
actions       = require 'app/flux/environment/actions'
SidebarWidget = require 'app/components/sidebarmachineslistitem/sidebarwidget'


module.exports = class StackUpdatedWidget extends React.Component

  @defaultProps =
    className   : 'StackUpdated'


  constructor: ->

    @state    =
      isShown : no


  componentWillReceiveProps: (nextProps) ->

    @setState { isShown : no }  if nextProps.show


  handleOnClick : ->
    { appManager, router } = kd.singletons
    appManager.tell 'Stackeditor', 'reloadEditor', @props.stack.get('baseTemplate').toJS()
    actions.reinitStackFromWidget @props.stack


  handleOnClose: ->

    @setState { isShown : yes }


  render: ->

    return null  if @state.isShown

    <SidebarWidget {...@props} onClose={@bound 'handleOnClose'}>
      <span>STACK UPDATED</span>
      <p className='SidebarWidget-Title'>You need to reinitialize your machines before booting.</p>
      <button className='kdbutton solid medium green reinit-stack' onClick={@bound 'handleOnClick'}>
        <span className='button-title'>UPDATE MY MACHINES</span>
      </button>
    </SidebarWidget>
