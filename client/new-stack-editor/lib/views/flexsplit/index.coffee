kd = require 'kd'

module.exports = class FlexSplit extends kd.View

  @EVENT_EXPAND   = 'FlexSplit.EXPAND'
  @EVENT_COLLAPSE = 'FlexSplit.COLLAPSE'
  @EVENT_RESIZED  = 'FlexSplit.RESIZED'

  @MAX = 100
  @MIN = 0.0001

  @HORIZONTAL =
    name      : 'horizontal'
    axis      : 'y'
    getter    : 'getHeight'

  @VERTICAL   =
    name      : 'vertical'
    axis      : 'x'
    getter    : 'getWidth'

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'flex-split', options.cssClass
    options.sizes     ?= []
    options.type      ?= FlexSplit.HORIZONTAL
    options.resizable ?= yes

    super options, data

    @resizer = null
    @type    = @getOption 'type'
    @setClass @type.name

    @setupViews()

  createResizer: (view, size) ->

    FlexSplitResizer = require './resizer'
    @resizer = @addSubView new FlexSplitResizer { @type, view }

    @resizer.on FlexSplit.EVENT_EXPAND, ->
      if view.parent instanceof FlexSplit
        view.parent.emit FlexSplit.EVENT_EXPAND
    @resizer.on FlexSplit.EVENT_COLLAPSE, ->
      if view.parent instanceof FlexSplit
        view.parent.emit FlexSplit.EVENT_COLLAPSE

  setupViews: ->

    { sizes, views, resizable } = @getOptions()

    views.forEach (view, index) =>

      unless view.hasClass 'flex-split'
        view.setClass 'flex-view'

      if sizes[index]?
        size = sizes[index]
        view.setCss 'flex-basis', "#{size}%"

      @addSubView view

      if resizable
        view.setCss 'flex-basis', '50%'  unless size?
        @resizer?.addView view, size
        if views[index + 1]
          @createResizer view, size
