kd = require 'kd'
Flex = require './constants'
FlexSplitResizer = require './resizer'


module.exports = class FlexSplit extends kd.View

  # Keep copy of constants on FlexSplit for external uses
  for own key, value of Flex
    FlexSplit[key] = value

  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'flex-split', options.cssClass
    options.sizes     ?= []
    options.type      ?= Flex.HORIZONTAL
    options.resizable ?= yes

    super options, data

    @_type = Flex.INSTANCE_TYPE

    @resizer = null
    { @type, @name, storage } = @getOptions()
    @setClass @type.name

    @setupViews()

    @on Flex.EVENT_RESIZED, =>
      view._windowDidResize?()  for view in @getOption 'views'

    storage?.addView this, @name


  createResizer: (view, size) ->

    @resizer = @addSubView new FlexSplitResizer { @type, view }

    @forwardEvents @resizer, [
      Flex.EVENT_EXPANDED
      Flex.EVENT_RESIZED
      Flex.EVENT_HIDDEN
      Flex.EVENT_COLLAPSED
    ]

    @resizer.on Flex.EVENT_EXPAND, ->
      if FlexSplit.isInstance view.parent
        view.parent.emit Flex.EVENT_EXPAND

    @resizer.on Flex.EVENT_COLLAPSE, ->
      if FlexSplit.isInstance view.parent
        view.parent.emit Flex.EVENT_COLLAPSE

    @resizer.on Flex.EVENT_RESIZED, =>
      { views } = @getOptions()
      views.forEach (view) ->
        view._windowDidResize?()
        if FlexSplit.isInstance view
          view.emit Flex.EVENT_RESIZED


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


  setFractions: (fractions, options) ->
    @resizer?.setFractions fractions, options


  @isInstance = (instance) ->
    instance?._type is Flex.INSTANCE_TYPE
