React = require 'app/react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Notification = require './Notification'
Label = require '../Text/Label'

class NotificationContainer extends React.Component

  constructor: (props) ->

    super props
    @_notification = null
    @type = @props.type


  _handleSimpleClick: ->

    @_notification.addNotification
      type : @type
      duration : 2000
      content : 'Lorem ipsum dolor sit amet'


  _handleDismissibleClick: ->

    @_notification.addNotification
      type : @type
      dismissible : yes
      content : 'Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet'
      onRemove : -> action 'button clicked'


  _handleSingleActionClick: ->

    @_notification.addNotification
      type : @type
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'


  _handleDoubleActionClick: ->

    @_notification.addNotification
      type : @type
      primaryButtonTitle : 'Submit'
      onPrimaryButtonClick : -> action 'button clicked'
      secondaryButtonTitle : 'Cancel'
      onSecondaryButtonClick : -> action 'button clicked'
      content : 'Lorem ipsum dolor sit amet'


  render: ->

    self = this
    <div>
      <Label size="xlarge">{@type.toUpperCase()}</Label>
      <div style={{marginBottom: 10}} />
      <div style={{marginBottom: 10}}><Button onClick={@bound '_handleSimpleClick'}>Simple Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound '_handleDismissibleClick'}>Dismissible Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound '_handleSingleActionClick'}>One action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound '_handleDoubleActionClick'}>Two actions Notification</Button></div>
      <Notification ref={(notification) -> self._notification = notification}/>
    </div>


storiesOf 'Notification', module
  .add 'default', ->
    <NotificationContainer type="default"/>
  .add 'update', ->
    <NotificationContainer type="update"/>
  .add 'success', ->
    <NotificationContainer type="success"/>
  .add 'warning', ->
    <NotificationContainer type="warning"/>
  .add 'caution', ->
    <NotificationContainer type="caution"/>
