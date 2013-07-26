###

  KDTooltip

  A tooltip has a position and a direction, relative to the delegate
  element it is attached to.

  Valid positioning types are 'top','bottom','left' and 'right'
  Valid direction types are 'top','bottom','left','right' and 'center'

  Should a tooltip move off-screen, it will be relocated to be fully
  visible.

###

class KDTooltip extends KDView

  constructor:(options,data)->

    options.bind   or= "mouseenter mouseleave"
    options.sticky ?= no

    super options, data

    @avoidDestroy = no
    @visible      = yes
    @parentView   = @getDelegate()

    # Container for positioning in the viewport
    @setClass 'kdtooltip'
    @setClass options.viewCssClass if options.viewCssClass?

    # Wrapper for the view and/or content of the tooltip
    @wrapper    = new KDView
      cssClass  : 'wrapper'

    # Arrow Container for Tooltip design arrows
    @arrow = new KDView
      cssClass : 'arrow'

    if @getOptions().animate then @setClass 'out' else @hide()

    @addListeners()
    KDView.appendToDOMBody @
    @remove()

  _show = (tooltip)->
    return if tooltip.visible
    document.body.appendChild tooltip.$()[0]
    KD.getSingleton('windowController').addLayer tooltip
    tooltip.emit 'MouseEnteredAnchor'
    tooltip.visible = yes

  show:(event)->

    return if @visible
    o = @getOptions()

    if o.selector
      selectorEntered = no

      @parentView.on 'mousemove', (mouseEvent)=>

        if $(mouseEvent.target).is(o.selector) and selectorEntered is no
          selectorEntered = yes
          _show @
        if not $(mouseEvent.target).is(o.selector) and selectorEntered
          return if $(mouseEvent.target).is @$()
          selectorEntered = no
          @emit 'MouseLeftAnchor'
    else _show @

    super

  hide: (event)->

    @utils.defer =>
      o = @getOptions()

      if event
        return if o.selector and not $(event.target).is o.selector
      @parentView.off 'mousemove'
      # to throttle super need to call it explicitly
      # KDView::show.call @
      super
      @emit 'MouseLeftAnchor'

  update:(o = @getOptions(), view = null)->
    unless view
      o.selector or= null
      o.title    or= ""
      @getOptions().title = o.title
      @setTitle o.title
      @display @getOptions()
    else
      @setView view

  addListeners:->

    o = @getOptions()

    if o.events
      @parentView.bindEvent name for name in o.events

    @parentView.on 'mouseenter', =>
      if @parentView.tooltip
        @show()
        @avoidDestroy = yes

    unless o.selector
      @parentView.on 'mouseleave', =>
        @avoidDestroy = no
        @delayedRemove 40

    @on 'mouseenter', =>
      @avoidDestroy = yes

    @on 'mouseleave', (event)=>
      return if $(event.target).is @parentView.$()
      @avoidDestroy = no
      @delayedRemove()

    @on 'MouseEnteredAnchor', =>
      @avoidDestroy = yes
      @delayedDisplay()

    @on 'MouseLeftAnchor', =>
      @avoidDestroy = no
      @delayedRemove()

    @on 'ReceivedClickElsewhere', @bound "remove"

  isCurrentlyRemovable:-> @avoidDestroy

  setView: (childView) ->
    return unless childView

    @wrapper.view.destroy() if @wrapper.view?

    if childView.constructorName
      {options, data, constructorName} = childView
      @childView = new constructorName options, data
    else
      @wrapper.addSubView childView

  getView:-> @childView

  delayedDisplay:(timeout = @getOptions().delayIn)->
    @utils.killWait @displayTimer
    @displayTimer = @utils.wait timeout, =>
      if @isCurrentlyRemovable()
        @display()
      else
        @delayedRemove()

  remove:->

    return unless @visible

    KD.getSingleton('windowController').removeLayer @
    document.body.removeChild @$()[0]
    @visible = no

  destroy:->

    @visible = no
    @parentView.tooltip = null
    delete @parentView.tooltip
    super

  delayedRemove:(timeout = @getOptions().delayOut)->

    return if @getOptions().sticky

    @utils.killWait @deleteTimer
    @deleteTimer = @utils.wait timeout, =>
      unless @isCurrentlyRemovable()
        if @getOptions().animate
          @unsetClass 'in'
          KD.getSingleton('windowController').enableScroll()
          @utils.killWait @animatedDeleteTimer
          @animatedDeleteTimer = @utils.wait 2000, @bound "remove"
        else
          KD.getSingleton('windowController').enableScroll()
          @remove()

  translateCompassDirections:(o)->

    {placement,gravity} = o
    o.placement = placementMap[placement]
    o.direction = directionMap(o.placement, gravity)

    return o

  display:(o = @getOptions())->

    # converts NESW-Values to topbottomleftright and retains them in @getOptions
    o = @translateCompassDirections o if o.gravity
    o.gravity = null

    @setClass 'in' if o.animate
    @show()
    @visible = yes
    KD.getSingleton('windowController').disableScroll()
    @setPosition o

  getCorrectPositionCoordinates:(o={},positionValues,callback=noop)->
    # values that can/will be used in all the submethods
    container       = @$()
    selector        = @parentView.$(o.selector)
    d = # dimensions
      container :
        height  : container.height()
        width   : container.width()
      selector  :
        offset  : selector.offset()
        height  : selector.height()
        width   : selector.width()

    {placement,direction} = positionValues

    # check the default values for overlapping boundaries, then
    # recalculate if there are overlaps

    violations = getBoundaryViolations getCoordsFromPlacement(d, placement, direction),\
    d.container.width, d.container.height

    if Object.keys(violations).length > 0 # check for possible alternatives
      variants = [
        ['top','right']
        ['right','top']
        ['right','bottom']
        ['bottom','right']
        ['top','left']
        ['top','center']
        ['right','center']

        ['bottom','center']
        ['bottom','left']
        ['left','bottom']
        ['left','center']
        ['left','top']
      ]

      for variant in variants
        if Object.keys(getBoundaryViolations(getCoordsFromPlacement(d,variant[0],variant[1]),\
        d.container.width, d.container.height)).length is 0
          [placement,direction] = variant
          break

    correctValues =
      coords : getCoordsFromPlacement d, placement, direction
      placement : placement
      direction : direction

    callback correctValues
    return correctValues

  setPosition:(o = @getOptions(),animate = no)->

    @setClass 'animate-movement' if animate

    placement = o.placement or 'top'
    direction = o.direction or 'right'

    offset =
      if Number is typeof o.offset
        top   : o.offset
        left  : 0
      else
        o.offset

    # Correct impossible combinations
    direction =
      if placement in ['top','bottom'] and direction in ['top','bottom']
        'center'
      else if placement in ['left','right'] and direction in ['left','right']
         'center'
        else direction

    # fetch corrected placement and coordinated for positioning
    {coords,placement,direction} = @getCorrectPositionCoordinates o,{placement,direction}
    # log coords

    # css classes for arrow positioning
    for placement_ in ['top','bottom','left','right']
      if placement is placement_
        @setClass 'placement-'+placement_
      else
        @unsetClass 'placement-'+placement_

    for direction_ in ['top','bottom','left','right','center']
      if direction is direction_
        @setClass 'direction-'+direction_
      else
        @unsetClass 'direction-'+direction_

    @$().css
      left : coords.left + offset.left
      top  : coords.top + offset.top

    @utils.wait 500, => @unsetClass 'animate-movement'

  setTitle:(title,o={})->
    unless o.html is no
      @wrapper.updatePartial title
    else
      @wrapper.updatePartial Encoder.htmlEncode title

  viewAppended:->
    super()
    o = @getOptions()

    if o.view?
      @setView o.view
    else
      @setClass 'just-text'
      @setTitle o.title, o

    # @setTemplate @pistachio()
    # @template.update()

    @parentView.emit 'TooltipReady'

    @addSubView @arrow
    @addSubView @wrapper


  # pistachio:->
  #   """
  #    {{> @arrow}}
  #    {{> @wrapper}}
  #   """

  directionMap = (placement, gravity)->
    if placement in ["top", "bottom"]
      if /e/.test gravity then "left"
      else if /w/.test gravity then "right"
      else "center"
    else if placement in ["left", "right"]
      if /n/.test gravity then "top"
      else if /s/.test gravity then "bottom"
      else placement

  placementMap =
    top     : "top"
    above   : "top"
    below   : "bottom"
    bottom  : "bottom"
    left    : "left"
    right   : "right"

  # will return an object with the amount of clipped pixels
  getBoundaryViolations = (coordinates,width,height)=>
    violations = {}
    if coordinates.left < 0
      violations.left   = -(coordinates.left)
    if coordinates.top  < 0
      violations.top    = -(coordinates.top)
    if coordinates.left+width > window.innerWidth
      violations.right  = coordinates.left+width-window.innerWidth
    if coordinates.top+height > window.innerHeight
      violations.bottom = coordinates.top+height-window.innerHeight
    violations

  getCoordsDiff = (dimensions,type,center=no)->
    diff = dimensions.selector[type]-dimensions.container[type]
    if center then diff/2 else diff

  getCoordsFromPlacement = (dimensions,placement,direction)->
    coordinates =
      top  : dimensions.selector.offset.top
      left : dimensions.selector.offset.left

    [staticAxis,dynamicAxis,staticC,dynamicC,exclusion] =
      if /o/.test placement then ['height','width','top','left','right']
      else ['width','height','left','top','bottom']

    coordinates[staticC]+= unless placement.length<5
        (dimensions.selector[staticAxis]+10)
      else -(dimensions.container[staticAxis]+10)

    unless direction is exclusion
      coordinates[dynamicC]+=getCoordsDiff(dimensions,dynamicAxis,direction is 'center')
    return coordinates
