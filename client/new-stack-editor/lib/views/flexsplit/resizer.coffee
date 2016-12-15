kd = require 'kd'
Flex = require './constants'


module.exports = class FlexSplitResizer extends kd.View

  constructor: (options = {}, data) ->

    options.type     ?= Flex.HORIZONTAL
    options.cssClass  = 'flex-resizer'
    options.draggable = { axis: options.type.axis }

    super options, data

    @views      = []
    @_fractions = []
    { @type, view } = @getOptions()

    @addView view

    @on 'DragFinished', @dragFinished
    @on 'DragStarted',  @dragStarted


  _getViewIndex: (view) ->
    if view is @views[0] then 0 else 1


  addView: (view) ->

    @views.push view

    view.on Flex.EVENT_EXPAND, =>

      return  if view.hasClass 'expanded'
      view.setClass 'expanded'

      @emit Flex.EVENT_EXPAND

      @_updateViewSizes()
      @_updateFractions 0, set = no

      fractions = []
      viewIndex = @_getViewIndex view
      for i in [0..1]
        fractions.push if i is viewIndex then Flex.MAX else Flex.MIN
        @_setViewFraction @views[i], fractions[i]

      @emit Flex.EVENT_EXPANDED, fractions
      view._windowDidResize?()


    view.on Flex.EVENT_COLLAPSE, =>

      @emit Flex.EVENT_COLLAPSE

      fractions = []
      viewIndex = @_getViewIndex view
      for i in [0..1]
        fractions.push @_fractions[i] ? 50
        @_setViewFraction @views[i], fractions[i]
        @views[i].unsetClass 'expanded'

      @emit Flex.EVENT_COLLAPSED, fractions
      view._windowDidResize?()


  _updateViewSizes: ->
    @sizes = [
      @views[0][@type.getter]()
      @views[1][@type.getter]()
    ]
    @totalSize = @sizes[0] + @sizes[1] + @[@type.getter]()


  limited = (num) ->
    Math.min Flex.MAX, Math.max Flex.MIN, num


  _updateFractions: (change = 0, set = yes) ->

    for i in [0..1]
      change = -change  if i is 1
      @_fractions[i] = limited ((change + @sizes[i]) / @totalSize) * Flex.MAX
      @_setViewFraction @views[i], @_fractions[i]  if set


  drag: (event, delta) ->
    @_updateFractions delta[@type.axis]


  dragFinished: (event, dragState) ->

    @unsetClass 'ondrag'
    @emit Flex.EVENT_RESIZED, @_fractions
    for view in @views
      view.unsetClass 'ondrag'
      view._windowDidResize?()


  dragStarted: (event, dragState) ->

    for view in @views
      view.unsetClass 'expanded'
      view.setClass 'ondrag'

    @setClass 'ondrag'

    @_updateViewSizes()


  setFractions: (fractions, set = yes) ->

    @_fractions = [fractions[0], fractions[1]]
    return  unless set
    @_setViewFraction @views[0], fractions[0]
    @_setViewFraction @views[1], fractions[1]


  _setViewFraction: (view, fraction) ->
    view.setCss 'flex-basis', "#{fraction}%"
    view._windowDidResize?()
