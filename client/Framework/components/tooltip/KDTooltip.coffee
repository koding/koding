class KDTooltip extends KDView
  constructor:(options,data)->

    options = $.extend {}, options,
      bind  : "mouseenter mouseleave"

    super options,data

    @options = options

    # Container for positioning in the viewport
    @setClass 'tooltip-container'
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

  display:->
    @show()
    @setPosition()

  setPosition:()->
    # measure the distance for proper placement
    container = @$()
    containerHeight = container.height()
    containerWidth = container.width()
    selector = @getDelegate().$(@options.selector)
    selectorOffset = selector.offset()
    selectorHeight = selector.height()
    selectorWidth = selector.width()

    # vertical placement defaults to above, so only paint below the
    # selector if specifically demanded or if there is not enough space
    if @options.placement is 'below' or (@options.placement is 'above' and selectorOffset.top-selectorHeight-containerHeight < 0)
      @setClass 'painted-below'
      @unsetClass 'painted-above'
      container.css top : selectorOffset.top+selectorHeight+10
    else
      @setClass 'painted-above'
      @unsetClass 'painted-below'
      container.css top : selectorOffset.top-containerHeight-10

    # horizontal placement defaults to right, will only paint left if
    # there is enough space for it.
    if @options.placement is 'left' or ( selectorOffset.left+containerWidth > window.innerWidth)
      @setClass 'painted-left'
      @unsetClass 'painted-right'
      container.css left : selectorOffset.left-containerWidth+selectorWidth
    else
      @setClass 'painted-right'
      @unsetClass 'painted-left'
      container.css left : selectorOffset.left

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