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

    # This will handle expand request of the view, it will set fraction
    # as Flex.MAX for requested view and will do Flex.MIN for other view
    # it will also fire the same event which will cause a chain reaction
    # on parent resizers to do same. It will allow us to expand nested
    # views up to the parent one ~ GG
    view.on Flex.EVENT_EXPAND, =>

      return  if view.hasClass 'expanded'
      view.setClass 'expanded'

      # This will start chain reaction for expanding parent views
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

    # This will handle collapse request of the view, it will set fraction
    # as Flex.MIN for requested view and will do Flex.MAX for other view
    # it will also fire the same event which will cause a chain reaction
    # on parent resizers to do same. It will allow us to collapse nested
    # views up to the parent one ~ GG
    view.on Flex.EVENT_COLLAPSE, =>

      # This will start chain reaction for collapsing parent views
      @emit Flex.EVENT_COLLAPSE

      fractions = []
      viewIndex = @_getViewIndex view
      for i in [0..1]
        fractions.push @_fractions[i] ? 50
        @_setViewFraction @views[i], fractions[i]
        @views[i].unsetClass 'expanded'

      @emit Flex.EVENT_COLLAPSED, fractions
      view._windowDidResize?()


    view.on Flex.EVENT_HIDE, =>

      fractions = [Flex.MAX, Flex.MAX]
      viewIndex = @_getViewIndex view
      fractions[viewIndex] = Flex.MIN

      for i in [0..1]
        @_setViewFraction @views[i], fractions[i]

      @emit Flex.EVENT_HIDDEN, fractions
      view._windowDidResize?()

    # Custom Resize events for programatically resize the view based on the
    # given percentage, the other side will be resized to Flex.MAX -
    # Triggering storage is optional and disabled by default ~ GG
    view.on Flex.EVENT_RESIZE, (options) =>

      { percentage = Flex.MIN, store = no } = options

      leftOver  = Flex.MAX - percentage
      fractions = [leftOver, leftOver]
      viewIndex = @_getViewIndex view
      fractions[viewIndex] = percentage

      for i in [0..1]
        @_setViewFraction @views[i], fractions[i]

      if store
        @emit Flex.EVENT_RESIZED, fractions

      view._windowDidResize?()


  _updateViewSizes: ->
    # This will get height or width of given views. This height or width
    # depends on the type of this FlexSplitResizer. For example; if we've
    # a horizontal resizer then getter will be `getHeight` look constants.
    @sizes = [
      @views[0][@type.getter]()
      @views[1][@type.getter]()
    ]

    # We need to know totalSize of the view including resizer's width or height
    # Since we are not defining resizer handle size in code but in style we
    # need to calculate that size dynamically as well
    #
    # This totalSize will become total width or total height of the FlexSplit
    @totalSize = @sizes[0] + @sizes[1] + @[@type.getter]()


  limited = (num) ->
    Math.min Flex.MAX, Math.max Flex.MIN, num


  _updateFractions: (change = 0, set = yes) ->
    # This will calculate fractions for each view and will leave enough space
    # for the resizer itself as well. For example on a 100px wide FlexSplit
    # if you have a 4px wide resizer 96px will be distributed on the views.
    # If they splitted even on the screen then their fractions will become
    # 48% and 48%, remaining 4% is used by the resizer itself. ~ GG
    for i in [0..1]
      change = -change  if i is 1
      @_fractions[i] = limited ((change + @sizes[i]) / @totalSize) * Flex.MAX
      @_setViewFraction @views[i], @_fractions[i]  if set


  drag: (event, delta) ->
    # on drag we are getting the delta based on the axis of this type
    # of resizer x for VERTICAL, y for HORIZONTAL ptl. constants.
    @_updateFractions delta[@type.axis]


  dragFinished: (event, dragState) ->

    @unsetClass 'ondrag'
    @emit Flex.EVENT_RESIZED, @_fractions
    for view in @views
      view.unsetClass 'ondrag'


  dragStarted: (event, dragState) ->

    for view in @views
      view.unsetClass 'expanded'
      view.setClass 'ondrag'

    @setClass 'ondrag'

    @_updateViewSizes()


  setFractions: (fractions, options = {}) ->

    { updateViews = yes, initialFractions = [50, 50] } = options

    @_fractions = initialFractions
    return  unless updateViews

    for index in [0..1]
      @_setViewFraction @views[index], fractions[index]
      if fractions[index] is Flex.MAX
        @views[index].setClass 'expanded'


  _setViewFraction: (view, fraction) ->
    view.setCss 'flex-basis', "#{fraction}%"
    view._windowDidResize?()
