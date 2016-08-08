kd = require 'kd'

module.exports = class TimeoutChecker extends kd.Object

  constructor: (options = {}) ->

    options.duration ?= 60
    super options

    @timer = null
    @lastPercentage = 0


  update: (percentage) ->

    return  if percentage is @lastPercentage

    @lastPercentage = percentage
    @stop()

    { duration } = @getOptions()
    @timer = kd.utils.wait duration * 1000, @lazyBound 'emit', 'Timeout'


  stop: ->

    kd.utils.killWait @timer
    @timer = null
