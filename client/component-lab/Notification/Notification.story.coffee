React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Notification = require './Notification'

class NotificationContainer extends React.Component

  constructor: (props) ->

    super props
    @_notification = null


  _handleSimpleClick: ->

    @_notification.addNotification
      type : 'update'
      duration : 2000
      content : 'Lorem ipsum dolor sit amet'
      noAnimation : yes


  _handleDismissibleClick: ->

    @_notification.addNotification
      type : 'success'
      dismissible : yes
      content : 'Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet'
      onRemove : -> action 'button clicked'
      noAnimation : yes


  _handlePrimarySuccessClick: ->

    @_notification.addNotification
      type : 'success'
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'
      noAnimation : yes


  _handlePrimaryUpdateClick: ->

    @_notification.addNotification
      type : 'update'
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'
      noAnimation : yes


  _handlePrimaryWarningClick: ->

    @_notification.addNotification
      type : 'warning'
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'
      noAnimation : yes


  _handlePrimaryCautionClick: ->

    @_notification.addNotification
      type : 'caution'
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'
      noAnimation : yes


  _handleSecondaryClick: ->

    @_notification.addNotification
      type : 'caution'
      primaryButtonTitle : 'Submit'
      onPrimaryButtonClick : -> action 'button clicked'
      secondaryButtonTitle : 'Cancel'
      onSecondaryButtonClick : -> action 'button clicked'
      content : 'Lorem ipsum dolor sit amet'
      noAnimation : yes


  render: ->

    self = this
    <div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleSimpleClick.bind this}>Simple Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleDismissibleClick.bind this}>Dismissible Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handlePrimarySuccessClick.bind this}>Primary Success action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handlePrimaryUpdateClick.bind this}>Primary Update action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handlePrimaryWarningClick.bind this}>Primary Warning action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handlePrimaryCautionClick.bind this}>Primary Caution action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleSecondaryClick.bind this}>Secondary action Notification</Button></div>
      <Notification ref={(notification) -> self._notification = notification}/>
    </div>


storiesOf 'Notification', module
  .add 'notifications', ->
    <NotificationContainer/>
