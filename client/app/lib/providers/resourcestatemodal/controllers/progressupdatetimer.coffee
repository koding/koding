kd = require 'kd'

module.exports = class ProgressUpdateTimer extends kd.Object

  MIN_UPDATE_COUNT    = 10
  MAX_UPDATE_INTERVAL = 5

  constructor: (options = {}) ->

    options.duration ?= 60
    super options

    @startTime = new Date().getTime()
    kd.utils.defer @bound 'updateProgress'


  updateProgress: ->

    { duration } = @getOptions()
    interval     = Math.min duration / MIN_UPDATE_COUNT, MAX_UPDATE_INTERVAL
    timeSpent    = (new Date().getTime() - @startTime) / 1000
    percentage   = Math.min 100, timeSpent * 100 / duration

    @emit 'ProgressUpdated', percentage

    @timer = kd.utils.wait interval * 1000, @bound 'updateProgress'  if percentage < 100


  stop: ->

    kd.utils.killWait @timer
    @timer = null
