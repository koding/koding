kd = require 'kd'
ActivityPane = require './activitypane'


module.exports = class SingleActivityPane extends ActivityPane

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'single-activity', options.cssClass

    super options, data

    @scrollView.wrapper.off 'LazyLoadThresholdReached'


  viewAppended: ->

    @tabView.tabHandleContainer.destroy()

    @addSubView @scrollView
    @scrollView.wrapper.addSubView @tabView
