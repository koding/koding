class KDScrollView extends KDView
  constructor:(options,data)->
    options = $.extend
      ownScrollBars : no
      bind          : "mouseenter"
    ,options
    super options,data
    @setClass "kdscrollview"

    # if @getOptions().ownScrollBars
    #   @_createScrollBars()

  bindEvents:()->
    @getDomElement().bind "scroll mousewheel",(event,delta,deltaX,deltaY)=> #FIXME: mousewheel works in FF, IE??
      event._delta = {delta,deltaX,deltaY} if delta
      @handleEvent event
    super

  viewAppended:->
    super

  handleEvent:(event)->
    # log event.type
    # thisEvent = @[event.type]? event or yes #this would be way awesomer than lines 98-103, but then we have to break camelcase convention in mouseUp, etc. names....??? worth it?
    switch event.type
      when "scroll" then thisEvent = @scroll event
      when "mousewheel" then thisEvent = @mouseWheel event
    superResponse = super event #always needs to be called for propagation
    thisEvent = thisEvent ? superResponse #only return superResponse if local handle didn't happen
    willPropagateToDOM = thisEvent

  hasScrollBars:()-> @getScrollHeight() > @getHeight()

  getScrollHeight:()-> @$()[0].scrollHeight
  getScrollWidth:()->  @$()[0].scrollWidth
  getScrollTop:()->    @$().scrollTop()
  getScrollLeft:()->   @$().scrollLeft()

  scrollTo:({top, left, duration},callback)->
    top      or= 0
    left     or= 0
    duration or= null

    if duration
      @$().animate
        scrollTop  : top
        scrollLeft : left
      , duration
      , ->
        callback?()
    else
      @$().scrollTop top
      @$().scrollLeft left
      callback?()

  scrollToSubView:(subView)->

    viewTop       = @getY()
    viewHeight    = @getHeight()
    viewScrollTop = @getScrollTop()
    subViewTop    = subView.getY()
    subViewHeight = subView.getHeight()
    subViewRelTop = subViewTop - viewTop + viewScrollTop

    # log "item is in visible area"
    if subViewTop - viewTop + subViewHeight < viewHeight and subViewTop - viewTop >= 0
      # log "item is in visible area"
      return

    # log "item is above visible area"
    else if subViewTop - viewTop < 0
      @scrollTo top : subViewRelTop

    # log "item is below visible area"
    else if subViewTop - viewTop + subViewHeight > viewHeight
      @scrollTo top : subViewRelTop - viewHeight + subViewHeight

  fractionOfHeightBelowFold:({view})->
    viewHeight = view.getHeight()
    viewGlobalOffset = view.$().offset().top
    scrollViewGlobalOffset = @$().offset().top
    viewOffsetFromScrollView = viewGlobalOffset - scrollViewGlobalOffset
    (viewHeight + viewOffsetFromScrollView - @getHeight())/@getHeight()

  mouseWheel:(event)->
    if $(event.target).attr("data-id") is @getId() and @ownScrollBars
      direction = if event._delta.delta > 0 then "up" else "down"
      @_scrollUponVelocity event._delta.delta,direction
      return no
    (@getSingleton "windowController").scrollingEnabled

  # scroll:(event)->
  #   if @getOptions().ownScrollBars
  #     scrollOffset = @$().scrollTop()
  #     @_vTrack.$().css marginTop : scrollOffset
  #   yes

  _scrollUponVelocity:(velocity,direction)->
    log direction, velocity,@getScrollHeight()
    stepInPixels     = velocity * 50
    actInnerPosition = @$().scrollTop()
    newInnerPosition = stepInPixels + actInnerPosition
    log stepInPixels,actInnerPosition,newInnerPosition
    @$().scrollTop newInnerPosition

  _createScrollBars:->
    log "has-own-scrollbars"
    @setClass "has-own-scrollbars"
    @addSubView @_vTrack = new KDView cssClass : 'kdscrolltrack ver',delegate : @
    # @addSubView @_hTrack = new KDView cssClass : 'kdscrolltrack hor',delegate : @
    @_vTrack.setRandomBG()
    # @_hTrack.setRandomBG()

    @_vTrack.addSubView @_vThumb = new KDScrollThumb cssClass : 'kdscrollthumb', type : "vertical",delegate : @_vTrack
    # @_hTrack.addSubView @_hThumb = new KDScrollThumb cssClass : 'kdscrollthumb', type : "horizontal",delegate : @_hTrack
    @scrollBarsCreated = yes
    @ownScrollBars = yes

class KDScrollThumb extends KDView
  constructor:(options,data)->
    options = $.extend
      type      : "vertical"    # "vertical" or "horizontal"
    ,options
    super options,data

    @_track = @getDelegate()
    @_view = @_track.getDelegate()

    @on "viewAppended", @_calculateSize.bind @

    @listenTo
      KDEventTypes : "scroll"
      listenedToInstance : @_view
      callback : @_calculatePosition

  isDraggable:()->yes

  dragOptions:->
    o = @getOptions()
    dragOptions =
      drag : @_drag
      containment : "parent"
    if o.type = "vertical"
      dragOptions.axis = "y"
    else
      dragOptions.axis = "x"

    dragOptions


  _drag:->
    log "dragged"

  _setSize:(size)->
    o = @getOptions()
    if o.type = "vertical"
      @setHeight size
    else
      @setWidth size

  _setOffset:(offset)->
    o = @getOptions()
    if o.type = "vertical"
      @$().css "marginTop" : offset
    else
      @$().css "marginLeft" : offset

  _calculateSize:->
    o = @getOptions()

    if o.type = "vertical"
      @_trackSize = @_view.getHeight()
      @_scrollSize = @_view.getScrollHeight()
      @_thumbMargin = @getY() - @_track.getY()
    else
      @_scrollSize = @parent.parent.getScrollWidth()
      @_thumbMargin = @getX() - @_track.getX()
      @_trackSize = @parent.getWidth()

    log @_trackSize,@_scrollSize

    @_track.hide() if @_trackSize >= @_scrollSize

    @_thumbRatio = @_trackSize / @_scrollSize
    @_thumbSize = @_trackSize * @_thumbRatio - 2 * @_thumbMargin

    @_setSize @_thumbSize

  _calculatePosition:=>
    viewScrollTop = @_view.$().scrollTop()
    thumbTopOffset = viewScrollTop * @_thumbRatio + @_thumbMargin
    @_setOffset thumbTopOffset


