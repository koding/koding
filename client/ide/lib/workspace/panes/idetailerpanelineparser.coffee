kd                 = require 'kd'
KDNotificationView = kd.NotificationView

showDoneNotification = -> showNotification 'Provisioning Completed'


showNotification = (message, duration = 2000) ->

  new KDNotificationView
    title    : message
    duration : duration


config = [
  { template : '_KD_DONE_', fn : showDoneNotification }
  { template : /^_KD_NOTIFY_@(.+)@$/, fn : showNotification }
]


module.exports = IDETailerPaneLineParser =

  process: (line) ->

    line = line.trim()
    for { template, fn } in config
      if template instanceof RegExp
        match = line.match template
        return fn.apply null, match.slice 1  if match
      else if line is template
        return fn()
