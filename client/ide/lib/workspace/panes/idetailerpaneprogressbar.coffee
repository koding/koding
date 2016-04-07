kd = require 'kd'

module.exports = class IDETailerPaneProgressBar extends kd.View

  INITIAL_WIDTH       = 5
  MIN_UPDATE_COUNT    = 10
  MAX_UPDATE_INTERVAL = 5

  constructor: (options = {}) ->

    options.cssClass = kd.utils.curry 'tailer-pane-progress-bar', options.cssClass

    super options

    { duration } = @getOptions()

    return @setClass 'hidden'  unless duration

    @startTime       = new Date().getTime()
    @addSubView @bar = new kd.View
      tagName : 'cite'

    kd.utils.defer @bound 'updateProgress'


  updateProgress: ->

    { duration } = @getOptions()
    interval     = Math.min duration / MIN_UPDATE_COUNT, MAX_UPDATE_INTERVAL
    timeSpent    = (new Date().getTime() - @startTime) / 1000
    percentage   = Math.min 100, timeSpent * 100 / duration

    @setBarWidth percentage

    @timer = kd.utils.wait interval * 1000, @bound 'updateProgress'  if percentage < 100


  completeProgress: ->

    @timer = kd.utils.killWait @timer
    @setBarWidth 100


  setBarWidth: (width) ->
      
    width = Math.max width, INITIAL_WIDTH
    @bar.setStyle { width: "#{width}%" }
