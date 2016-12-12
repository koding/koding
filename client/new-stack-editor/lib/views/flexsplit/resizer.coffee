kd = require 'kd'
FlexSplit = require './index'

module.exports = class FlexSplitResizer extends kd.View

  constructor: (options = {}, data) ->

    options.type     ?= FlexSplit.HORIZONTAL
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

    view.on FlexSplit.EVENT_EXPAND, =>

      return  if view.hasClass 'expanded'
      view.setClass 'expanded'

      @emit FlexSplit.EVENT_EXPAND

      @_updateViewSizes()
      @_updateFractions 0, set = no

      fractions = []
      viewIndex = @_getViewIndex view
      for i in [0..1]
        fractions.push if i is viewIndex then FlexSplit.MAX else FlexSplit.MIN
        @_setViewFraction i, fractions[i]

      @emit FlexSplit.EVENT_EXPANDED, fractions


    view.on FlexSplit.EVENT_COLLAPSE, =>

      @emit FlexSplit.EVENT_COLLAPSE

      fractions = []
      viewIndex = @_getViewIndex view
      for i in [0..1]
        fractions.push @_fractions[i] ? 50
        @_setViewFraction i, fractions[i]
        @views[i].unsetClass 'expanded'

      @emit FlexSplit.EVENT_COLLAPSED, fractions


  _updateViewSizes: ->
    @sizes = [
      @views[0][@type.getter]()
      @views[1][@type.getter]()
    ]
    @totalSize = @sizes[0] + @sizes[1] + @[@type.getter]()


  limited = (num) ->
    Math.min FlexSplit.MAX, Math.max FlexSplit.MIN, num


  _updateFractions: (change = 0, set = yes) ->

    for i in [0..1]
      change = -change  if i is 1
      @_fractions[i] = limited ((change + @sizes[i]) / @totalSize) * FlexSplit.MAX
      @_setViewFraction i, @_fractions[i]  if set


  drag: (event, delta) ->
    @_updateFractions delta[@type.axis]


  dragFinished: (event, dragState) ->

    view.unsetClass 'ondrag'  for view in @views
    @unsetClass 'ondrag'
    @emit FlexSplit.EVENT_RESIZED, @_fractions


  dragStarted: (event, dragState) ->

    for view in @views
      view.unsetClass 'expanded'
      view.setClass 'ondrag'

    @setClass 'ondrag'

    @_updateViewSizes()


  setFractions: (fractions) ->

    @_fractions = [fractions[0], fractions[1]]
    @_setViewFraction 0, fractions[0]
    @_setViewFraction 1, fractions[1]


  _setViewFraction: (viewIndex, fraction) ->
    @views[viewIndex].setCss 'flex-basis', "#{fraction}%"
