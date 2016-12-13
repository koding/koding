kd = require 'kd'

module.exports = class FlexSplit extends kd.View

  @EVENT_EXPAND    = 'FlexSplit.EXPAND'
  @EVENT_COLLAPSE  = 'FlexSplit.COLLAPSE'

  @EVENT_RESIZED   = 'FlexSplit.RESIZED'
  @EVENT_EXPANDED  = 'FlexSplit.EXPANDED'
  @EVENT_COLLAPSED = 'FlexSplit.COLLAPSED'

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
    { @type, @name, storage } = @getOptions()
    @setClass @type.name

    @setupViews()

    storage?.addView this, @name


  createResizer: (view, size) ->

    # This needs to be here to prevent circular dependency ~ GG
    FlexSplitResizer = require './resizer'

    @resizer = @addSubView new FlexSplitResizer { @type, view }

    @forwardEvents @resizer, [
      FlexSplit.EVENT_EXPANDED
      FlexSplit.EVENT_RESIZED
      FlexSplit.EVENT_COLLAPSED
    ]

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


  setFractions: (fractions, set = yes) ->
    @resizer?.setFractions fractions, set
