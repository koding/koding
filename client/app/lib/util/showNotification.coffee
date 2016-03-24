kd = require 'kd'
KDNotificationView = kd.NotificationView
module.exports = (message, options = {}) ->
  return  if not message or message is ''

  # TODO these css/type parameters will be changed according to error type
  type = 'growl'

  options.duration or= 3500
  options.title      = message
  # options.css      or= css
  options.type     or= type

  options.fn message  if options.fn and typeof options.fn? is 'function'

  new KDNotificationView options
