kd = require 'kd'
_ = require 'lodash'

NotificationViewContainer = require 'lab/Notification/NotificationViewContainer'

Constants = require 'lab/Notification/constants'
Helpers = require 'lab/Notification/helpers'

module.exports = class NotificationViewController extends kd.Controller

  constructor: (options = {}, data) ->

    super options, data
    @container = new NotificationViewContainer
    @container.appendToDomBody()
    @uid = 1000


  addNotification: (notificationOptions) =>

    notification = _.assign {}, Constants.notification, notificationOptions
    Helpers.validateProps notification, Constants.types
    notifications = @getNotificationOptions 'notifications'
    notification.type = notification.type.toLowerCase()
    notification.duration = parseInt notification.duration, 10
    notification.uid = notification.uid or @uid
    notification.ref = "notification-#{notification.uid}"
    @uid += 1
    return no for notificationOptions in notifications when notificationOptions.uid is notification.uid
    notifications.unshift notification
    if typeof notification.onAdd is 'function'
      notificationOptions.onAdd notification
    @container.updateOptions { notifications }
    return notification

  getNotificationOptions: (option) ->

    @container.options[option]
