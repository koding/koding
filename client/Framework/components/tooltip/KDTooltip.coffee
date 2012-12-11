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

    @options = options

    # Container for positioning in the viewport
    @setClass 'kdtooltip'
    @setClass options.viewCssClass if options.viewCssClass?

    # Wrapper for the view and/or content of the tooltip
    @wrapper    = new KDView
      cssClass  : 'wrapper'

    # Arrow Container for Tooltip design arrows
    @arrow = new KDView
      cssClass : 'arrow'

    if @options.animate
      @setClass 'out'
    else
      @hide()

    @mouseOver = no
    @mouseOverAnchor = no

    @on 'mouseenter', =>
      @mouseOver = yes

    @on 'mouseleave', =>
      @mouseOver = no
      @delayedDestroy()

    @on 'MouseEnteredAnchor', =>
      @mouseOverAnchor = yes
      @delayedDisplay()

    @on 'MouseLeftAnchor', =>
      @mouseOverAnchor = no
      @delayedDestroy()

  setView:(newView)->
    return unless newView

    if @wrapper.view?
      @wrapper.removeSubView @wrapper.view

    viewOptions = $.extend {},newView.options, {delegate:@getDelegate()}
    @view = new newView.constructorName viewOptions, newView.data
    @wrapper.addSubView @view

  getView:->
    @view

  delayedDisplay:(timeout=500)->
    setTimeout =>
      if @mouseOverAnchor
        @display()
      else
        @delayedDestroy()
    ,timeout

  delayedDestroy:(timeout=500)->
    setTimeout =>
      unless @mouseOver or @mouseOverAnchor
        if @options.animate
          @unsetClass 'in'
          setTimeout =>
            @getDelegate().removeTooltip @
          ,2000
        else
          @hide()
          @getDelegate().removeTooltip @
    ,timeout

  display:(o=@options)->
    if o.animate
      @show()
      @setClass 'in'
    else
      @show()
    @setPosition(o)

  getCorrectPositionCoordinates:(o={},positionValues,callback=noop)->
    # values that can/will be used in all the submethods
    container       = @$()
    containerHeight = container.height()
    containerWidth  = container.width()
    selector        = @getDelegate().$(o.selector)
    selectorOffset  = selector.offset()
    selectorHeight  = selector.height()
    selectorWidth   = selector.width()

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

    # get default coordinates for tooltip placement
    getCoordsFromPositionValues = (placement,direction)=>

      c =
        top  : selectorOffset.top
        left : selectorOffset.left

      switch placement
        when 'top'
          c.top       -= containerHeight+10
          switch direction
            when 'left'
              c.left  += selectorWidth-containerWidth
            when 'center'
              c.left  += (selectorWidth-containerWidth)/2
        when 'bottom'
          c.top       += selectorHeight+10
          switch direction
            when 'left'
              c.left  += selectorWidth-containerWidth
            when 'center'
              c.left  += (selectorWidth-containerWidth)/2
        when 'right'
          c.left      += selectorWidth+10
          switch direction
            when 'top'
              c.top   += selectorHeight-containerHeight
            when 'center'
              c.top   += (selectorHeight-containerHeight)/2
        when 'left'
          c.left      -= containerWidth+25
          switch direction
            when 'top'
              c.top   += selectorHeight-containerHeight
            when 'center'
              c.top   += (selectorHeight-containerHeight)/2
      return c

    {placement,direction} = positionValues

    # check the default values for overlapping boundaries, then
    # recalculate if there are overlaps
    v = boundaryViolations getCoordsFromPositionValues(placement, direction), containerWidth, containerHeight

    unless v is {}
      if v.top and v.left
        placement     = 'bottom'
        direction     = 'right'
      else if v.top and v.right
        placement     = 'bottom'
        direction     = 'left'
      else if v.bottom and v.left
        placement     = 'top'
        direction     = 'right'
      else if v.bottom and v.right
        placement     = 'top'
        direction     = 'left'
      else if v.top
        if placement in ['left','right']
          direction   = placement
        placement     = 'bottom'
      else if v.bottom
        if placement in ['left','right']
          direction   = placement
        placement     = 'top'
      else if v.left
        if placement is 'top'
          direction   = 'right'
        else
          if placement is 'bottom'
            direction = 'bottom'
          placement   = 'right'
      else if v.right
        if placement is 'top'
          direction   = 'left'
        else
          if  placement is 'bottom'
            direction = 'bottom'
          placement   = 'left'

    correctValues =
      coords : getCoordsFromPositionValues placement, direction
      placement : placement
      direction : direction

    callback correctValues
    return correctValues

  setPosition:(o={})->

    placement = o.placement or 'top'
    direction = o.direction or 'right'

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
      left : coords.left
      top : coords.top

  viewAppended:->
    super()
    @setView @options.view

    @setTemplate @pistachio()
    @template.update()

    if @getDelegate()?
      @getDelegate().emit 'TooltipReady'
    else
      @parent.emit 'TooltipReady'

  pistachio:->
    """
     {{> @arrow}}
     {{> @wrapper}}
    """