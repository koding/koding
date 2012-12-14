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

    options = $.extend {}, options,
      bind  : "mouseenter mouseleave"

    super options,data

    @avoidDestroy = no

    # Container for positioning in the viewport
    @setClass 'kdtooltip'
    @setClass options.viewCssClass if options.viewCssClass?

    # Wrapper for the view and/or content of the tooltip
    @wrapper    = new KDView
      cssClass  : 'wrapper'

    # Arrow Container for Tooltip design arrows
    @arrow = new KDView
      cssClass : 'arrow'

    if @getOptions().animate
      @setClass 'out'
    else
      @hide()

    KDView.appendToDOMBody @
    @getSingleton('windowController').addLayer @
    @addListeners()

  addListeners:->
    @on 'mouseenter', =>
      @avoidDestroy = yes

    @on 'mouseleave', =>
      @avoidDestroy = no
      @delayedDestroy()

    @on 'MouseEnteredAnchor', =>
      @avoidDestroy = yes
      @delayedDisplay()

    @on 'MouseLeftAnchor', =>
      @avoidDestroy = no
      @delayedDestroy()

    @on 'ReceivedClickElsewhere', =>
      @delayedDestroy 0


  setView:(newView)->
    return unless newView

    if @wrapper.view?
      @wrapper.removeSubView @wrapper.view

    {options, data, constructorName} = newView

    options.delegate ?= @getDelegate()
    @view = new constructorName options, data
    @wrapper.addSubView @view

  getView:->
    @view

  delayedDisplay:(timeout = @getOptions().delayIn)->
    @utils.killWait @displayTimer
    @displayTimer = @utils.wait timeout, =>
      if @avoidDestroy
        @display()
      else
        @delayedDestroy()

  delayedDestroy:(timeout = @getOptions().delayOut)->
    @utils.killWait @deleteTimer
    @deleteTimer = @utils.wait timeout, =>
      unless @avoidDestroy
        # return 1
        if @getOptions().animate
          @unsetClass 'in'

          @utils.killWait @animatedDeleteTimer
          @animatedDeleteTimer = @utils.wait 2000, =>

            @getDelegate().removeTooltip @

        else
          @getDelegate().removeTooltip @

  translateCompassDirections:(o)->

    {placement,gravity} = o
    o.placement = placementMap[placement]
    o.direction = directionMap(o.placement, gravity)

    return o

  display:(o = @getOptions())->

    # converts NESW-Values to topbottomleftright and retains them in
    # @getOptions
    o = @translateCompassDirections o if o.gravity
    o.gravity = null

    @setClass 'in' if o.animate
    @show()
    @setPosition(o)

  getCorrectPositionCoordinates:(o={},positionValues,callback=noop)->
    # values that can/will be used in all the submethods
    container       = @$()
    selector        = @getDelegate().$(o.selector)
    d = # dimensions
      container :
        height  : container.height()
        width   : container.width()
      selector  :
        offset  : selector.offset()
        height  : selector.height()
        width   : selector.width()

    # get default coordinates for tooltip placement
    getCoordsFromPositionValues = (placement,direction)=>

      c = # coordinates
        top  : d.selector.offset.top
        left : d.selector.offset.left

      cDiff = (dimensions,type,center=no)->
        (dimensions.selector[type]-dimensions.container[type])/(1+center)
        # if center then diff/2 else diff

      getCoordsFromPlacement = (coordinates,dimensions,placement,direction)->
        [staticAxis,dynamicAxis,staticC,dynamicC,exclusion] =
          if /o/.test placement then ['height','width','top','left','right']
          else ['width','height','left','top','bottom']
        coordinates[staticC]+= unless placement.length<5
            (dimensions.selector[staticAxis]+10)
          else -(dimensions.container[staticAxis]+10)
        unless direction is exclusion
          coordinates[dynamicC]+=cDiff(dimensions,dynamicAxis,direction is 'center')
        return coordinates

      return getCoordsFromPlacement c,d,placement,direction

      # return c

      # switch placement
      #   when 'top'
      #     c.top       -= d.container.height+10
      #     unless direction is 'right'
      #       c.left += cDiff(d,'width',direction is 'center')
      #   when 'bottom'
      #     c.top       += d.selector.height+10
      #     unless direction is 'right'
      #       c.left  += cDiff(d,'width',direction is 'center')
      #   when 'right'
      #     c.left      += d.selector.width+10
      #     unless direction is 'bottom'
      #       c.top   += cDiff(d,'height',direction is 'center')
      #   when 'left'
      #     c.left      -= d.container.width+10
      #     unless direction is 'bottom'
      #       c.top   += cDiff(d,'height',direction is 'center')

          # switch direction
          #   when 'left'
          #     c.left  += cDiff(d,'width')
          #   when 'center'
          #     c.left  += cDiff(d,'width',yes)
          # switch direction
          #   when 'left'
          #     c.left  += cDiff(d,'width')
          #   when 'center'
          #     c.left  += cDiff(d,'width',yes)
          # switch direction
          #   when 'top'
          #     c.top   += cDiff(d,'height')
          #   when 'center'
          #     c.top   += cDiff(d,'height',yes)
          # switch direction
          #   when 'top'
          #     c.top   += cDiff(d,'height')
          #   when 'center'
          #     c.top   += cDiff(d,'height',yes)
      # return c

    {placement,direction} = positionValues

    # check the default values for overlapping boundaries, then
    # recalculate if there are overlaps

    violations = boundaryViolations getCoordsFromPositionValues(placement, direction), d.container.width, d.container.height

    if Object.keys(violations).length > 0
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
        if Object.keys(boundaryViolations(getCoordsFromPositionValues(variant[0],variant[1]), d.container.width, d.container.height)).length is 0
          [placement,direction] = variant
          break

    correctValues =
      coords : getCoordsFromPositionValues placement, direction
      placement : placement
      direction : direction

    callback correctValues
    return correctValues

  setPosition:(o={})->

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
      left : coords.left+offset.left
      top : coords.top+offset.top

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

    @setTemplate @pistachio()
    @template.update()

    if @getDelegate()?
      @getDelegate().emit 'TooltipReady'
    else
      @parent?.emit 'TooltipReady'

  pistachio:->
    """
     {{> @arrow}}
     {{> @wrapper}}
    """

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
  boundaryViolations = (coordinates,width,height)=>
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
