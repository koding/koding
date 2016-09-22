kd            = require 'kd'
immutable     = require 'immutable'
React         = require 'app/react'
actions       = require 'app/flux/environment/actions'
SidebarWidget = require 'app/components/sidebarmachineslistitem/sidebarwidget'


module.exports = class StackUpdatedWidget extends React.Component

  @defaultProps =
    className   : 'StackUpdated'
    visible     : no
    onClose     : kd.noop
    stack       : immutable.Map()


  handleOnClick : ->

    { appManager, router } = kd.singletons
    templateId =  @props.stack.get 'baseStackId'
    actions.reinitStackFromWidget(@props.stack).then ->
      appManager.tell 'Stackeditor', 'reloadEditor', templateId


  render: ->

    return null  unless @props.visible

    <SidebarWidget {...@props} onClose={@props.onClose}>
      <span>STACK UPDATED</span>
      <p className='SidebarWidget-Title'>You need to reinitialize your machines before booting.</p>
      <button className='kdbutton solid medium green reinit-stack' onClick={@bound 'handleOnClick'}>
        <span className='button-title'>UPDATE MY MACHINES</span>
      </button>
    </SidebarWidget>
