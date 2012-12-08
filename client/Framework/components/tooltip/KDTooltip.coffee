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
    @wrapper = new KDView
      cssClass : 'wrapper'

    # Arrow Container for Tooltip design arrows
    @arrow = new KDView
      cssClass : 'arrow'

    @hide()

    @mouseOver = no

    @on 'mouseenter', =>
      @mouseOver = yes

    @on 'mouseleave', =>
      @mouseOver = no
      @delayedHide()

  setView:(newView)->
    return unless newView

    if @wrapper.view?
      @wrapper.removeSubView @wrapper.view

    viewOptions = $.extend {},newView.options, {delegate:@getDelegate()}
    @view = new newView.constructorName viewOptions, newView.data
    @wrapper.addSubView @view

  getView:->
    @view

  delayedHide:(timeout=500)->
    setTimeout =>
      unless @mouseOver
        @hide()
    ,timeout

  display:(o=@options)->
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
        violations.left = -(coordinates.left)
      if coordinates.top < 0
        violations.top = -(coordinates.top)
      if coordinates.left+width > window.innerWidth
        violations.right = coordinates.left+width-window.innerWidth
      if coordinates.top+height > window.innerHeight
        violations.bottom = coordinates.top+height-window.innerHeight
      violations

    # get default coordinates for tooltip placement
    getCoordsFromPositionValues = (placement,direction)=>
      switch placement
        when 'top'
          switch direction
            when 'right'
              top : selectorOffset.top-containerHeight-10
              left : selectorOffset.left
            when 'left'
              top : selectorOffset.top-containerHeight-10
              left : selectorOffset.left-containerWidth+selectorWidth
            when 'center','top','bottom'
              top : selectorOffset.top-containerHeight-10
              left : selectorOffset.left+(selectorWidth-containerWidth)/2
        when 'bottom'
          switch direction
            when 'right'
              top : selectorOffset.top+selectorHeight+10
              left : selectorOffset.left
            when 'left'
              top : selectorOffset.top+selectorHeight+10
              left : selectorOffset.left-containerWidth+selectorWidth
            when 'center','top','bottom'
              top : selectorOffset.top+selectorHeight+10
              left : selectorOffset.left+(selectorWidth-containerWidth)/2
        when 'right'
          switch direction
            when 'top'
              top : selectorOffset.top
              left : selectorOffset.left+selectorWidth+10
            when 'bottom'
              top : selectorOffset.top+selectorHeight-containerHeight
              left : selectorOffset.left+selectorWidth+10
            when 'center','right','left'
              top : selectorOffset.top+(selectorHeight-containerHeight)/2
              left : selectorOffset.left+selectorWidth+10
        when 'left'
          switch direction
            when 'top'
              top : selectorOffset.top
              left : selectorOffset.left-containerWidth-25
            when 'bottom'
              top : selectorOffset.top+selectorHeight-containerHeight
              left : selectorOffset.left-containerWidth-25
            when 'center','right','left'
              top : selectorOffset.top+(selectorHeight-containerHeight)/2
              left : selectorOffset.left-containerWidth-25

    {placement,direction} = positionValues

    # check the default values for overlapping boundaries, then
    # recalculate if there are overlaps
    v = boundaryViolations getCoordsFromPositionValues(placement, direction), containerWidth, containerHeight

    unless v is {}

      if v.top and v.left
        placement = 'bottom'
        direction = 'right'
      else if v.top and v.right
        placement = 'bottom'
        direction = 'left'
      else if v.top
        if placement in ['left','right']
          direction = placement
        placement = 'bottom'
      else if v.bottom and v.left
        placement = 'top'
        direction = 'right'
      else if v.bottom and v.right
        placement = 'top'
        direction = 'left'
      else if v.bottom
        if placement in ['left','right']
          direction = placement
        placement = 'top'
      else if v.left
        if placement is 'top'
          direction = 'top'
        else if placement is 'bottom'
          direction = 'bottom'
        placement = 'right'
      else if v.right
        if placement is 'top'
          direction = 'top'
        else if  placement is 'bottom'
          direction = 'bottom'
        placement = 'left'

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

    @$().css
      left : coords.left
      top : coords.top

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