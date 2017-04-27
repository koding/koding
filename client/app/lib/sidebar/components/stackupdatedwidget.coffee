kd = require 'kd'
React = require 'app/react'
SidebarWidget = require './widget'


module.exports = class StackUpdatedWidget extends React.Component

  @defaultProps =
    className: 'StackUpdated'
    onClose: kd.noop


  onClick: ->

    { appManager, router, computeController, sidebar } = kd.singletons

    sidebar.setUpdatedStack null
    templateId =  @props.stack.baseStackId

    computeController.reinitStack @props.stack, (err) =>
      appManager.tell 'Stackeditor', 'reloadEditor', templateId


  render: ->

    <SidebarWidget {...@props} onClose={@props.onClose}>
      <span>STACK UPDATED</span>
      <p className='SidebarWidget-Title'>
        You need to reinitialize your machines before booting.
      </p>
      <button
        className='kdbutton solid medium green reinit-stack'
        onClick={@bound 'onClick'}>
        <span className='button-title'>UPDATE MY MACHINES</span>
      </button>
    </SidebarWidget>
