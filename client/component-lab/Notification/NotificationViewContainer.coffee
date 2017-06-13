React = require 'app/react'
ReactView = require 'app/react/reactview'

NotificationView = require './NotificationView'

classnames = require 'classnames'
styles = require './Notification.stylus'

module.exports = class NotificationViewContainer extends ReactView

  constructor: (options = {}, data) ->

    options.appendToDomBody ?= yes
    options.notifications ?= []
    super options
    @appendToDomBody()  if @getOptions().appendToDomBody


  onNotificationRemove: (uid) =>

    notifications = @options.notifications
    notifications = notifications.filter (n) -> n.uid isnt uid

    @options.notifications = notifications
    @updateOptions { notifications }


  getNotifications: ->

    @options.notifications.map (notification, index) =>
      <NotificationView
        index={index}
        key={notification.uid}
        notification={notification}
        onRemove={@bound 'onNotificationRemove'} />


  renderReact: ->

    stateClass = if @options.notifications.length
    then ''
    else 'hidden'

    className = classnames [
      styles.kd_notification_list
      stateClass
    ]

    <div className={className}>
      { @getNotifications() }
    </div>
