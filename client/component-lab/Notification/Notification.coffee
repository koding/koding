_ = require 'lodash'
React = require 'react'

NotificationView = require './NotificationView'
FlipMove = require 'react-flip-move'

styles = require './Notification.stylus'
Constants = require './constants'

module.exports = class Notification extends React.Component

  constructor: (props) ->

    super props
    @uid = 1000
    @_isMounted = no
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
      noAnimation: no
    @addNotification = @addNotification.bind this
    @_didNotificationRemoved = @_didNotificationRemoved.bind this

  addNotification: (notification) ->

    _notification = _.assign({}, Constants.notification, notification)
    notifications = @state.notifications
    i = null
    if not _notification.type
      throw new Error('Notification type is required.')
    if _.keys(Constants.types).indexOf(_notification.type) is -1
      throw new Error("\"#{_notification.type} \" is not a valid type.")
    if isNaN(_notification.duration)
      throw new Error('\"duration\" must be a number.')
    _notification.type = _notification.type.toLowerCase()
    _notification.duration = parseInt(_notification.duration, 10)
    _notification.uid = _notification.uid or @uid
    _notification.ref = "notification-#{_notification.uid}"
    @uid += 1
    i = 0
    while i < notifications.length
      if notifications[i].uid is _notification.uid
        return no
      i++
    notifications.push _notification
    if typeof _notification.onAdd is 'function'
      notification.onAdd _notification
    @setState { notifications : notifications }
    _notification


  _didNotificationRemoved: (uid) ->
    notification = null
    notifications = _.filter @state.notifications, (toCheck) ->
      if toCheck.uid is uid
        notification = toCheck
      toCheck.uid isnt uid
    if notification and notification.onRemove
      notification.onRemove notification
    if @_isMounted
      @setState { notifications : notifications }
    return


  componentDidMount: ->

    @_isMounted = yes


  componentWillUnmount: ->

    @_isMounted = no


  render: ->

    self = this
    notifications = null
    notifications = _.map @state.notifications, (notification, index) ->
      <NotificationView
        index={index}
        key={notification.uid}
        noAnimation={notification.noAnimation}
        notification={notification}
        onRemove={self._didNotificationRemoved} />
    <div className={styles.kd_notification_list}>
      <FlipMove
        enterAnimation={@_enterAnimation}
        leaveAnimation={@_leaveAnimation}>
        { notifications }
      </FlipMove>
    </div>
