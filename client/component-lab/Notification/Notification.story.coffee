React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Notification = require './Notification'

class NotificationContainer extends React.Component

  constructor: (props) ->

    super props
    @_notification = null


  componentDidMount: ->

    @_notification = @refs.notification


  _handleSimpleClick: ->

    @_notification.addNotification
      type : 'update'
      duration : 2000
      content : 'Lorem ipsum dolor sit amet'
      noAnimation : false


  _handleDismissibleClick: ->

    @_notification.addNotification
      type : 'success'
      dismissible : true
      content : 'Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet'
      onRemove : -> action 'button clicked'
      noAnimation : false


  _handlePrimaryClick: ->

    @_notification.addNotification
      type : 'warning'
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'
      noAnimation : false


  _handleSecondaryClick: ->

    @_notification.addNotification
      type : 'caution'
      primaryButtonTitle : 'Submit'
      onPrimaryButtonClick : -> action 'button clicked'
      secondaryButtonTitle : 'Cancel'
      onSecondaryButtonClick : -> action 'button clicked'
      content : 'Lorem ipsum dolor sit amet'
      noAnimation : false


  render: ->
    
    <div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleSimpleClick.bind this}>Simple Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleDismissibleClick.bind this}>Dismissible Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handlePrimaryClick.bind this}>Primary action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@_handleSecondaryClick.bind this}>Secondary action Notification</Button></div>
      <Notification ref="notification"/>
    </div>


storiesOf 'Notification', module
  .add 'notifications', ->
    <NotificationContainer/>
