kd = require 'kd'
KDCustomScrollView = kd.CustomScrollView
KDView = kd.View


module.exports = class ContentDisplayScrollableView extends KDView

  constructor: (options = {}, data) ->

    options.type = options.contentDisplay.getOptions().type

    super options, data

    @listenWindowResize()


  viewAppended: ->

    @scrollView = new KDCustomScrollView
      lazyLoadThreshold : 100

    @scrollView.wrapper.addSubView @getOptions().contentDisplay

    @addSubView @scrollView

    @forwardEvent @scrollView.wrapper, 'LazyLoadThresholdReached'


  _windowDidResize: ->

    @getOptions().contentDisplay.setCss { minHeight : global.innerHeight }
    @scrollView.setHeight global.innerHeight
