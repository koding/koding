kd                 = require 'kd'
KDObject           = kd.Object
KDNotificationView = kd.NotificationView

module.exports = class IDETailerPaneLineParser extends KDObject

  constructor: ->

    super

    @config = [
      { template : '_KD_DONE_', method : @lazyBound 'emit', 'BuildDone' }
      { template : /_KD_NOTIFY_@(.+)@/, method : @lazyBound 'emit', 'BuildNotification' }
    ]


  process: (line) ->

    line = line.trim()
    for { template, method } in @config
      if template instanceof RegExp
        match = line.match template
        return method.apply null, match.slice(1)  if match
      else if line.indexOf(template) > -1
        return method()
