kd = require 'kd'
KDObject = kd.Object
module.exports = class IdleUserDetector extends KDObject
  constructor: (options, data) ->
    super options, data

    @detectIdleUser()

  detectIdleUser: ->
    { threshold } = @getOptions()
    global.addEventListener 'mousemove',  (@bound 'notIdle'), yes # capture
    global.addEventListener 'keypress',   (@bound 'notIdle'), yes # capture
    kd.utils.repeat 1000, =>
      @idle()  if Date.now() - @idleSince > threshold
    @notIdle()

  idle: ->
    wasIdle = @isIdle
    @isIdle = yes
    @emit 'userIdle'  unless wasIdle

  notIdle: ->
    wasIdle = @isIdle
    @isIdle = no
    @idleSince = Date.now()
    @emit 'userBack'  if wasIdle
