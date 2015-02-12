class IdleUserDetector extends KDObject
  constructor: (options, data) ->
    super options, data

    @detectIdleUser()

  detectIdleUser: ->
    { threshold } = @getOptions()
    window.addEventListener 'mousemove',  (@bound 'notIdle'), yes # capture
    window.addEventListener 'keypress',   (@bound 'notIdle'), yes # capture
    KD.utils.repeat 1000, =>
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
