React = require 'react'
Constants = require './constants'
NotificationView = require './NotificationView'

styles = require './Notification.stylus'

module.exports = Notification = React.createClass

  uid : 1000
  _isMounted : false

  getInitialState: ->
    {
      notifications : []
      noAnimation : false
    }


  addNotification: (notification) ->

    _notification = Object.assign({}, Constants.notification, notification)
    notifications = @state.notifications
    i = null
    if not _notification.type
      throw new Error('Notification type is required.')
    if Object.keys(Constants.types).indexOf(_notification.type) is -1
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
        return false
      i++
    notifications.push _notification
    if typeof _notification.onAdd is 'function'
      notification.onAdd _notification
    @setState notifications : notifications
    _notification


  removeNotification: (notification) ->

    self = this
    Object.keys(self.refs.container.refs).forEach (_notification) ->
      uid = if notification.uid then notification.uid else notification
      if _notification is "notification-#{uid}"
        self.refs.container.refs[_notification]._hideNotification()
      return
    return


  _didNotificationRemoved: (uid) ->

    notification = null
    notifications = @state.notifications.filter((toCheck) ->
      if toCheck.uid is uid
        notification = toCheck
      toCheck.uid isnt uid
    )
    if notification and notification.onRemove
      notification.onRemove notification
    if @isMounted
      @setState notifications : notifications
    return


  componentDidMount: ->

    @_isMounted = true
    return


  componentWillUnmount: ->

    @_isMounted = false
    return


  render: ->
    
    self = this
    notifications = null
    notifications = @state.notifications.map((notification) ->
      <NotificationView
        ref={"notification-#{notification.uid}"}
        key={notification.uid}
        noAnimation={notification.noAnimation}
        notification={notification}
        onRemove={self._didNotificationRemoved}/>)
    <div className={styles.kd_notification_list} ref="container">
      { notifications }
    </div>
