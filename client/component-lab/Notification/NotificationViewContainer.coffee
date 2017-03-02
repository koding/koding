React = require 'app/react'
ReactView = require 'app/react/reactview'

NotificationView = require './NotificationView'
FlipMove = require 'react-flip-move'

classnames = require 'classnames'
styles = require './Notification.stylus'

module.exports = class NotificationViewContainer extends ReactView

  constructor: (options = {}, data) ->

    options.appendToDomBody ?= yes
    options.notifications ?= []
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody


  getAnimationProps: ->

    enter :
      from :
        transform : 'scale(0.9)'
        opacity : 0
      to :
        transform : ''
        opacity : ''
    leave :
      from :
        transform : 'scale(1)'
        opacity : 1
      to :
        transform : 'scale(0.9)'
        opacity : 0


  onNotificationRemove: (uid) =>

    notification = null
    notifications = @options.notifications
    notifications = notifications.filter (n) ->
      notification = n if n.uid is uid
      n.uid isnt uid
    notification.onRemove notification  if notification && notification.onRemove
    @options.notifications = notifications
    @appendToDomBody()


  getNotifications: ->

    @options.notifications.map (notification, index) =>
      <NotificationView
        index={index}
        key={notification.uid}
        notification={notification}
        onRemove={@bound 'onNotificationRemove'} />


  renderReact: ->

    { enter, leave } = @getAnimationProps()

    stateClass = if @options.notifications.length
    then ''
    else 'hidden'

    className = classnames [
      styles.kd_notification_list
      stateClass
    ]

    <div className={className}>
      <FlipMove
        enterAnimation={enter}
        leaveAnimation={leave}>
        { @getNotifications() }
      </FlipMove>
    </div>
