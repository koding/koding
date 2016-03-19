kd = require 'kd'
KDNotificationView = kd.NotificationView
module.exports = (message, type = '', duration = 3500) ->
  new KDNotificationView
    cssClass : type
    title    : message
    duration : duration
