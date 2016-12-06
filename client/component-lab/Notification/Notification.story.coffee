kd = require 'kd'
React = require 'app/react'
{ storiesOf, action } = require '@kadira/storybook'
Button = require 'lab/Button'
Label = require 'lab/Text/Label'

class NotificationContainer extends React.Component

  constructor: (props) ->

    super props
    @type = @props.type


  handleSimpleClick: ->

    kd.singletons.notificationViewController.addNotification
      type : @type
      duration : 2000
      content : 'Lorem ipsum dolor sit amet'


  handleDismissibleClick: ->

    kd.singletons.notificationViewController.addNotification
      type : @type
      dismissible : yes
      content : 'Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet'
      onRemove : -> action 'button clicked'


  handleSingleActionClick: ->

    kd.singletons.notificationViewController.addNotification
      type : @type
      content : 'Lorem ipsum dolor sit amet'
      primaryButtonTitle : 'Install'
      onPrimaryButtonClick : -> action 'button clicked'


  handleDoubleActionClick: ->

    kd.singletons.notificationViewController.addNotification
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
      <div style={{marginBottom: 10}}><Button onClick={@bound 'handleSimpleClick'}>Simple Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound 'handleDismissibleClick'}>Dismissible Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound 'handleSingleActionClick'}>One action Notification</Button></div>
      <div style={{marginBottom: 10}}><Button onClick={@bound 'handleDoubleActionClick'}>Two actions Notification</Button></div>
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
