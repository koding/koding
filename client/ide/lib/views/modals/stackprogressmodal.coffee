kd = require 'kd'
KDModalView = kd.ModalView
KDProgressBarView = kd.ProgressBarView

module.exports = class StackProgressModal extends KDModalView

  MIN_UPDATE_COUNT    = 10
  MAX_UPDATE_INTERVAL = 5

  constructor: (options, data) ->

    options.title          ?= 'Stack building progress'
    options.cssClass        = kd.utils.curry 'stack-progress-modal', options.cssClass
    options.appendToDomBody = no
    options.view            = progressBar = new KDProgressBarView()
    
    super options, data

    @startTime   = new Date().getTime()
    @progressBar = progressBar
    @progressBar.once 'viewAppended', @bound 'updateProgress'

    { container } = @getOptions()
    container.addSubView this


  updateProgress: ->

    { duration } = @getOptions()
    interval     = Math.min duration / MIN_UPDATE_COUNT, MAX_UPDATE_INTERVAL
    timeSpent    = (new Date().getTime() - @startTime) / 1000
    percentage   = Math.min 100, timeSpent * 100 / duration

    @progressBar.updateBar percentage

    @timer = kd.utils.wait interval * 1000, @bound 'updateProgress'  if percentage < 100


  completeProgress: ->

    @timer = kd.utils.killWait @timer
    @progressBar.updateBar 100
    kd.utils.wait 500, @bound 'destroy'
