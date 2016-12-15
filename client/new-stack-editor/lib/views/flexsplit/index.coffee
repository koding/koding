kd = require 'kd'
Flex = require './constants'


module.exports = class FlexSplit extends kd.View


  constructor: (options = {}, data) ->

    options.cssClass   = kd.utils.curry 'flex-split', options.cssClass
    options.sizes     ?= []
    options.type      ?= Flex.HORIZONTAL
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
      Flex.EVENT_EXPANDED
      Flex.EVENT_RESIZED
      Flex.EVENT_COLLAPSED
    ]

    @resizer.on Flex.EVENT_EXPAND, ->
      if view.parent instanceof FlexSplit
        view.parent.emit Flex.EVENT_EXPAND

    @resizer.on Flex.EVENT_COLLAPSE, ->
      if view.parent instanceof FlexSplit
        view.parent.emit Flex.EVENT_COLLAPSE


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
