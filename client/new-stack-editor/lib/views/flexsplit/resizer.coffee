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

      viewIndex = @_getViewIndex view
      for i in [0..1]
        fraction = if i is viewIndex then FlexSplit.MAX else FlexSplit.MIN
        @views[i].setCss 'flex-basis', "#{fraction}%"

      kd.utils.wait 500, @bound 'hide'


    view.on FlexSplit.EVENT_COLLAPSE, =>

      @emit FlexSplit.EVENT_COLLAPSE

      viewIndex = @_getViewIndex view
      for i in [0..1]
        @views[i].setCss 'flex-basis', "#{@_fractions[i] ? 50}%"
        @views[i].unsetClass 'expanded'

      @show()


  _updateViewSizes: ->
    @sizes = [
      @views[0][@type.getter]()
      @views[1][@type.getter]()
    ]
    @totalSize = @sizes[0] + @sizes[1] + @[@type.getter]()

  limited = (num) -> Math.min FlexSplit.MAX, Math.max FlexSplit.MIN, num

  _updateFractions: (change = 0, set = yes) ->
    for i in [0..1]
      change = -change  if i is 1
      @_fractions[i] = limited ((change + @sizes[i]) / @totalSize) * FlexSplit.MAX
      @views[i].setCss 'flex-basis', "#{@_fractions[i]}%"  if set

  drag: (event, delta) ->
    @_updateFractions delta[@type.axis]

  dragFinished: (event, dragState) ->

    view.unsetClass 'ondrag'  for view in @views
    @unsetClass 'ondrag'

  dragStarted: (event, dragState) ->

    for view in @views
      view.unsetClass 'expanded'
      view.setClass 'ondrag'

    @setClass 'ondrag'

    @_updateViewSizes()
