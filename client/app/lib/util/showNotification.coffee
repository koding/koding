kd = require 'kd'

###
  Basic Usage showNotification { content: 'Notification Content' }
  The paramater notification object must have at least content attribute
  AddNotification func use default params for not provided attributes
  For ex, { type: 'default', dismissible: no, duration: 2000 }
###

module.exports = (notification = {}) ->

  return  unless notification.content

  { notificationViewController } = kd.singletons

  notificationViewController.addNotification notification
