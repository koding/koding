kd = require 'kd'
_ = require 'lodash'

NotificationContainer = require '../../component-lab/Notification/NotificationContainer'

Constants = require '../../component-lab/Notification/constants'
Helpers = require '../../component-lab/Notification/helpers'

module.exports = class NotificationViewController extends kd.Controller

  constructor: (options = {}, data) ->

    super options, data
    @container = new NotificationContainer
    @container.appendToDomBody()
    @uid = 1000


  addNotification: (notificationOptions) ->

    _notification = _.assign {}, Constants.notification, notificationOptions
    Helpers.validateProps _notification, Constants.types
    notifications = @getNotificationOptions "notifications"
    _notification.type = _notification.type.toLowerCase()
    _notification.duration = parseInt _notification.duration, 10
    _notification.uid = _notification.uid or @uid
    _notification.ref = "notification-#{_notification.uid}"
    @uid += 1
    return no for notificationOptions in notifications when notificationOptions.uid is _notification.uid
    notifications.push _notification
    if typeof _notification.onAdd is 'function'
      notificationOptions.onAdd _notification
    @container.updateOptions { notifications }
    _notification


  getNotificationOptions: (option) ->

    @container.options[option]


  onNotificationRemove: (uid) ->

    notification = null
    notifications = @getNotificationOptions notifications
    notifications = notifications.filter (n) ->
      notification = n if n.uid is uid
      n.uid isnt uid
    notification.onRemove notification  if notification && notification.onRemove
    @container.updateOptions { notifications }
