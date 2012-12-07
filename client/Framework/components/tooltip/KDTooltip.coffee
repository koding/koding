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
      cssClass : 'tooltip-wrapper'

    # Arrow Containers for Tooltip design arrows
    @arrowBelow = new KDView
      cssClass : 'tooltip-arrow-below'
    @arrowAbove = new KDView
      cssClass : 'tooltip-arrow-above'

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

  getPositionCoordinates:(o={},positionValues,callback=noop)->
    container = @$()
    containerHeight = container.height()
    containerWidth = container.width()
    selector = @getDelegate().$(o.selector)
    selectorOffset = selector.offset()
    selectorHeight = selector.height()
    selectorWidth = selector.width()

    {placement,direction} = positionValues
    coordinates = {}

    coordinates = switch placement
      when 'above'
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
      when 'below'
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
            left : selectorOffset.left-containerWidth-10
          when 'bottom'
            top : selectorOffset.top+selectorHeight-containerHeight
            left : selectorOffset.left-containerWidth-10
          when 'center','right','left'
            top : selectorOffset.top+(selectorHeight-containerHeight)/2
            left : selectorOffset.left-containerWidth-10

    callback coordinates
    return coordinates

  setPosition:(o={})->
    # measure the distance for proper placement
    container = @$()
    containerHeight = container.height()
    containerWidth = container.width()
    selector = @getDelegate().$(o.selector)
    selectorOffset = selector.offset()
    selectorHeight = selector.height()
    selectorWidth = selector.width()

    placement = o.placement or 'above'
    direction = o.direction or 'right'

    direction =
      if placement in ['above','below'] and direction in ['top','bottom']
        'center'
      else if placement in ['left','right'] and direction in ['left','right']
         'center'
        else direction

    log placement,direction

    # Sanity check here
    if placement is 'below' or (placement is 'above' and selectorOffset.top-selectorHeight-containerHeight < 0)
      placement = 'below'

    coords = @getPositionCoordinates o,{placement,direction}

    container.css
      left : coords.left
      top : coords.top

    for placement_ in ['above','below','left','right']
      if placement is placement_
        @setClass 'placement-'+placement_
      else
        @unsetClass 'placement-'+placement_

    for direction_ in ['top','bottom','left','right','center']
      if direction is direction_
        @setClass 'direction-'+direction_
      else
        @unsetClass 'direction-'+direction_



    # vertical placement defaults to above, so only paint below the
    # selector if specifically demanded or if there is not enough space
    # if o.placement is 'below' or (o.placement is 'above' and selectorOffset.top-selectorHeight-containerHeight < 0)
    #   @setClass 'painted-below'
    #   @unsetClass 'painted-above'
    #   # container.css top : selectorOffset.top+selectorHeight+10
    # else
    #   if o.placement is 'above'
    #     @setClass 'painted-above'
    #     @unsetClass 'painted-below'
    #     # container.css top : selectorOffset.top-containerHeight-10

    # # horizontal placement defaults to right, will only paint left if
    # # there is enough space for it.
    # if o.direction is 'left' or ( selectorOffset.left+containerWidth > window.innerWidth)
    #   @setClass 'direction-left'
    #   @unsetClass 'direction-right'
    #   # container.css left : selectorOffset.left-containerWidth+selectorWidth
    # else
    #   @setClass 'direction-right'
    #   @unsetClass 'direction-left'
    #   # container.css left : selectorOffset.left

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
     {{> @arrowAbove}}
     {{> @wrapper}}
     {{> @arrowBelow}}
    """