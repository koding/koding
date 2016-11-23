_ = require 'lodash'
React = require 'app/react'

NotificationView = require './NotificationView'
FlipMove = require 'react-flip-move'

styles = require './Notification.stylus'
Constants = require './constants'
Helpers = require './helpers'

module.exports = class Notification extends React.Component

  constructor: (props) ->

    super props
    @uid = 1000
    @_enterAnimation =
       from :
         transform : 'scale(0.9)'
         opacity : 0
       to :
        transform : ''
        opacity : ''
    @_leaveAnimation =
       from :
         transform : 'scale(1)'
         opacity : 1
       to :
        transform : 'scale(0.9)'
        opacity : 0
    @state =
      notifications: []

  addNotification: (notification) ->

    _notification = _.assign {}, Constants.notification, notification
    Helpers.propsValidation _notification, Constants.types
    notifications = @state.notifications
    _notification.type = _notification.type.toLowerCase()
    _notification.duration = parseInt _notification.duration, 10
    _notification.uid = _notification.uid or @uid
    _notification.ref = "notification-#{_notification.uid}"
    @uid += 1
    return no for notification in notifications when notification.uid is _notification.uid
    notifications.push _notification
    if typeof _notification.onAdd is 'function'
      notification.onAdd _notification
    @setState { notifications : notifications }
    _notification


  onNotificationRemove: (uid) ->
    notification = null
    notifications = @state.notifications.filter (n) ->
      notification = n if n.uid is uid
      n.uid isnt uid

    notification.onRemove notification if notification && notification.onRemove
    @setState { notifications }


  getAnimationProps: ->
    {
      enter:
         from :
           transform : 'scale(0.9)'
           opacity : 0
         to :
          transform : ''
          opacity : ''
      leave:
         from :
           transform : 'scale(1)'
           opacity : 1
         to :
          transform : 'scale(0.9)'
          opacity : 0
    }

  getNotifications: ->

    notifications = null
    notifications = _.map @state.notifications, (notification, index) =>
      <NotificationView
        index={index}
        key={notification.uid}
        notification={notification}
        onRemove={@bound 'onNotificationRemove'} />

  render: ->

    { enter, leave } = @getAnimationProps()
    <div className={styles.kd_notification_list}>
      <FlipMove
        enterAnimation={enter}
        leaveAnimation={leave}>
        { @getNotifications() }
      </FlipMove>
    </div>
