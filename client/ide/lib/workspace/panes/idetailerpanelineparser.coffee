kd                 = require 'kd'
KDObject           = kd.Object
KDNotificationView = kd.NotificationView

module.exports = class IDETailerPaneLineParser extends KDObject

  constructor: (file) ->

    @file = file
    @config = [
      { template : '_KD_DONE_', method : @bound 'showDoneNotification' }
      { template : /^_KD_NOTIFY_@(.+)@$/, method : @bound 'showNotification' }
    ]

  process: (line, file) ->

    line = line.trim()
    for { template, method } in @config
      if template instanceof RegExp
        match = line.match template
        return method.apply null, match.slice(1)  if match
      else if line is template
        return method()


  showDoneNotification: ->

    @showNotification 'Provisioning Completed'
    kd.singletons.computeController.emit 'StackBuildDone', @file.machine._id


  showNotification: (message, duration = 2000) ->

    new KDNotificationView
      title    : message
      duration : duration
