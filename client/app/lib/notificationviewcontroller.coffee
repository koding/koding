kd = require 'kd'
_ = require 'lodash'

NotificationViewContainer = require '../../component-lab/Notification/NotificationViewContainer'

Constants = require '../../component-lab/Notification/constants'
Helpers = require '../../component-lab/Notification/helpers'

module.exports = class NotificationViewController extends kd.Controller

  constructor: (options = {}, data) ->

    super options, data
    @container = new NotificationViewContainer
    @container.appendToDomBody()
    @uid = 1000


  addNotification: (notificationOptions) =>

    _notification = _.assign {}, Constants.notification, notificationOptions
    Helpers.validateProps _notification, Constants.types
    notifications = @getNotificationOptions 'notifications'
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
