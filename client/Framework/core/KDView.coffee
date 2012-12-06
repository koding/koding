class KDView extends KDObject

# #
# CLASS LEVEL STUFF
# #

  {defineProperty} = Object

  deprecated = (methodName)-> warn "#{methodName} is deprecated from KDView if you need it override in your subclass"

  eventNames =
    ///
    ^(
    (dbl)?click|
    key(up|down|press)|
    mouse(up|down|over|enter|leave|move)|
    drag(start|end|enter|leave|over)|
    blur|change|focus|
    drop|
    contextmenu|
    scroll|
    paste|
    error
    )$
    ///

  eventToMethodMap = ->
    dblclick    : "dblClick"
    keyup       : "keyUp"
    keydown     : "keyDown"
    keypress    : "keyPress"
    mouseup     : "mouseUp"
    mousedown   : "mouseDown"
    mouseenter  : "mouseEnter"
    mouseleave  : "mouseLeave"
    mousemove   : "mouseMove"
    contextmenu : "contextMenu"
    dragstart   : "dragStart"
    dragenter   : "dragEnter"
    dragleave   : "dragLeave"
    dragover    : "dragOver"
    paste       : "paste"


  overrideAndMergeObjects = (objects)->
    for own title,item of objects.overridden
      continue if objects.overrider[title]
      objects.overrider[title] = item
    objects.overrider

  @appendToDOMBody = (view)->
    $("body").append view.$()
    view.parentIsInDom = yes
    view.emit "viewAppended", view

# #
# INSTANCE LEVEL
# #

  constructor:(options = {},data)->

    o = options
    o.tagName     or= "div"     # a String of a HTML tag
    o.domId       or= null      # a String
    o.cssClass    or= ""        # a String
    o.parent      or= null      # a KDView Instance
    o.partial     or= null      # a String of HTML or text
    o.pistachio   or= null      # a String of Pistachio
    o.delegate    or= null      # a KDView Instance
    o.bind        or= ""        # a String of space seperated javascript dom events to be listened on instantiated view
    o.draggable   or= null      # an Object holding draggable options and/or events !!! NOT HTML5 !!!
    o.droppable   or= null      # TBDL
    o.size        or= null      # an Object holding width and height properties
    o.position    or= null      # an Object holding top/right/bottom/left properties (would force view to be positioned absolutely)
    o.attributes  or= null      # an Object holding attribute key/value pairs e.g. {href:'#',title:'my picture'}
    o.prefix      or= ""        # a String
    o.suffix      or= ""        # a String
    o.tooltip     or= null      # an Object of twipsy options
    # TO BE IMPLEMENTED
    o.resizable   or= null      # TBDL
    super o,data

    data?.on? 'update', => @render()

    @setInstanceVariables options
    @defaultInit options,data

    if location.hostname is "localhost"
      @listenTo
        KDEventTypes        : "click"
        listenedToInstance  : @
        callback            : (publishingInstance, event)=>
          if event.metaKey and event.altKey and event.ctrlKey
            log @getData()
            event.stopPropagation?()
            event.preventDefault?()
            return false
          else if event.altKey and (event.metaKey or event.ctrlKey)
            log @
            return false

    @on 'childAppended', @childAppended.bind @

    @on 'viewAppended', =>
      @setViewReady()
      @viewAppended()
      @childAppended @
      @parentIsInDom = yes
      subViews = @getSubViews()
      # temp fix for KDTreeView
      # subviews are stored in an object not in an array
      # hmm not really sth weirder going on...
      type = $.type subViews
      if type is "array"
        for child in subViews
          unless child.parentIsInDom
            child.parentIsInDom = yes
            child.emit 'viewAppended', child
      else if type is "object"
        for key,child of subViews
          unless child.parentIsInDom
            child.parentIsInDom = yes
            child.emit 'viewAppended', child


  setTemplate:(tmpl, params=@pistachioParams)->
    options = if params? then {params}
    @template = new Pistachio @, tmpl, options
    @updatePartial @template.html
    @template.embedSubViews()

  pistachio:(tmpl)->
    "#{@options.prefix}#{tmpl}#{@options.suffix}"

  setParent:(parent)->
    if @parent?
      log "view:", @, "parent:", @parent
      error 'View already has a parent'
    else
      if defineProperty
        defineProperty @, 'parent', value : parent, configurable : yes
      else
        @parent = parent

  unsetParent:()->
    delete @parent

  embedChild:(placeholderId, child, isCustom)->
    unless isCustom
      $child = child.$().attr 'id', child.id
      @$('#'+placeholderId).replaceWith $child
    else
      @$('#'+placeholderId).append(child.$())
    child.setParent @
    @subViews.push child
    child.emit 'viewAppended', child

  getTagName:-> @options.tagName || 'div'

  render:->
    if @template?
      @template.update()
    # else if 'function' is typeof @partial and data = @getData()
    #   @updatePartial @partial data

  setInstanceVariables:(options)->
    {@domId, @parent} = options
    @subViews = []

  defaultInit:(options,data)->
    @setDomElement options.cssClass
    @setDataId()
    @setDomId options.domId                       if options.domId
    @setDomAttributes options.attributes          if options.attributes
    @setSize options.size                         if options.size
    @setPosition options.position                 if options.position
    @setPartial options.partial                   if options.partial
    @addEventHandlers options

    if options.pistachio
      @setTemplate options.pistachio, options.pistachioParams
      @template.update()

    @setLazyLoader options.lazyLoadThreshold      if options.lazyLoadThreshold


    @setTooltip options.tooltip if options.tooltip
    @setDraggable options.draggable if options.draggable


    @bindEvents()

# #
# VIEW PROPERTY GETTERS
# #

  getDomId:()->
    @domElement.attr "id"


# #
# DOM ELEMENT CREATION
# #

  setDomElement:(cssClass)->
    cssClass = if cssClass then " #{cssClass}" else ""
    @domElement = $ "<#{@options.tagName} class='kdview#{cssClass}'></#{@options.tagName} >"

  setDomId:(id)->
    @domElement.attr "id",id


  setDataId:()->
    @domElement.data "data-id",@getId()

  setDomAttributes:(attributes)->
    @domElement.attr attributes

  isInDom:do ->
    findUltimateAncestor =(el)->
      ancestor = el
      while ancestor.parentNode
        ancestor = ancestor.parentNode
      ancestor
    -> findUltimateAncestor(@$()[0]).body?

# #
# TRAVERSE DOM ELEMENT
# #

  getDomElement:()-> @domElement

  getElement:-> @getDomElement()[0]

  # shortcut method for @getDomElement()
  $ :(selector)->
    if selector?
      @getDomElement().find(selector)
    else
      @getDomElement()

# #
# MANIPULATE DOM ELEMENT
# #
  # TODO: DRY these out.
  append:(child, selector)->
    @$(selector).append child.$()
    if @parentIsInDom
      child.emit 'viewAppended', child
    @

  appendTo:(parent, selector)->
    @$().appendTo parent.$(selector)
    if @parentIsInDom
      @emit 'viewAppended', @
    @

  prepend:(child, selector)->
    @$(selector).prepend child.$()
    if @parentIsInDom
      child.emit 'viewAppended', child
    @

  prependTo:(parent, selector)->
    @$().prependTo parent.$(selector)
    if @parentIsInDom
      @emit 'viewAppended', @
    @

  setPartial:(partial,selector)->
    @$(selector).append partial
    @

  updatePartial: (partial, selector) ->
    @$(selector).html partial

  # UPDATE PARTIAL EXPERIMENT TO NOT TO ORPHAN SUBVIEWS

  # updatePartial: (partial, selector) ->
  #   subViews = @getSubViews()
  #   subViewSelectors = for subView in subViews
  #     subView.$().parent().attr "class"
  #
  #   @$(selector).html partial
  #
  #   for subView,i in subViews
  #     @$(subViewSelectors[i]).append subView.$()


# #
# CSS METHODS
# #

  setClass:(cssClass)->
    @$().addClass cssClass
    @

  unsetClass:(cssClass)->
    @$().removeClass cssClass
    @

  toggleClass:(cssClass)->
    @$().toggleClass cssClass
    @

  getBounds:()->
    #return false unless @viewDidAppend
    bounds =
      x : @getX()
      y : @getY()
      w : @getWidth()
      h : @getHeight()
      n : @constructor.name

  setRandomBG:()->@getDomElement().css "background-color", __utils.getRandomRGB()

  hide:(duration)->
    @setClass 'hidden'
    # @$().hide duration
    #@getDomElement()[0].style.display = "none"

  show:(duration)->
    @unsetClass 'hidden'
    # @$().show duration
    #@getDomElement()[0].style.display = "block"

  setSize:(sizes)->
    @setWidth   sizes.width  if sizes.width?
    @setHeight  sizes.height if sizes.height?

  setPosition:()->
    positionOptions = @getOptions().position
    positionOptions.position = "absolute"
    @$().css positionOptions

  getWidth:()->
    w = @getDomElement().width()

  setWidth:(w)->
    @getDomElement()[0].style.width = "#{w}px"
    # @getDomElement().width w
    @emit "ViewResized", newWidth : w

  getHeight:()->
    # @getDomElement()[0].clientHeight
    @getDomElement().outerHeight(no)

  setHeight:(h)->
    @getDomElement()[0].style.height = "#{h}px"
    # @getDomElement().height h
    @emit "ViewResized", newHeight : h

  getX:()->@getDomElement().offset().left
  getRelativeX:()->@$().position().left
  setX:(x)->@$().css left : x
  getY:()->@getDomElement().offset().top
  getRelativeY:->@getDomElement().position().top
  setY:(y)->@$().css top : y

# #
# ADD/DESTROY VIEW INSTANCES
# #

  destroy:()->
    # instance destroys own subviews
    @destroySubViews() if @getSubViews().length > 0

    # instance drops itself from its parent's subviews array
    if @parent and @parent.subViews?
      @parent.removeSubView @

    # instance removes itself from DOM
    @getDomElement().remove()

    if @$overlay?
      @removeOverlay()

    # call super to remove instance subscriptions
    # and delete instance from KD.instances registry
    super()

  destroySubViews:()->
    # (subView.destroy() for subView in @getSubViews())

    for subView in @getSubViews().slice()
      if subView instanceof KDView
        subView?.destroy?()

  addSubView:(subView,selector,shouldPrepend)->
    unless subView?
      throw new Error 'no subview was specified'
    if subView.parent and subView.parent instanceof KDView
      index = subView.parent.subViews.indexOf subView
      if index > -1
        subView.parent.subViews.splice index, 1

    @subViews.push subView

    subView.setParent @

    subView.parentIsInDom = @parentIsInDom

    if shouldPrepend
      @prepend subView, selector
    else
      @append subView, selector

    subView.on "ViewResized", => subView.parentDidResize()

    if @template?
      @template["#{if shouldPrepend then 'prepend' else 'append'}Child"]? subView

    return subView

  getSubViews:->
    ###
    FIX: NEEDS REFACTORING
    used in @destroy
    not always sub views stored in @subviews but in @items, @itemsOrdered etc
    see KDListView KDTreeView etc. and fix it.
    ###
    subViews = @subViews
    if @items?
      subViews = subViews.concat [].slice.call @items
    subViews

  removeSubView:(subViewInstance)->
    for subView,i in @subViews
      if subViewInstance is subView
        @subViews.splice(i,1)
        subViewInstance.getDomElement().detach()
        subViewInstance.unsetParent()
        subViewInstance.handleEvent { type : "viewRemoved"}

  parentDidResize:(parent,event)->
    if @getSubViews()
      (subView.parentDidResize(parent,event) for subView in @getSubViews())

# #
# EVENT BINDING/HANDLING
# #


  setLazyLoader:(threshold=.75)->
    @getOptions().bind += ' scroll' unless /\bscroll\b/.test @getOptions().bind
    @listenTo
      KDEventTypes: 'scroll'
      listenedToInstance: @
      callback: do ->
        lastRatio = 0
        (publishingInstance, event)->
          el = @$()[0]
          ratio = (el.scrollTop+@getHeight()) / el.scrollHeight
          if ratio > lastRatio and ratio > threshold
            @handleEvent {type: 'LazyLoadThresholdReached', ratio}
          lastRatio = ratio

  # counter = 0
  bindEvents:($elm)->
    $elm or= @getDomElement()
    # defaultEvents = "mousedown mouseup click dblclick dragstart dragenter dragleave dragover drop resize"
    defaultEvents = "mousedown mouseup click dblclick paste"
    instanceEvents = @getOptions().bind

    eventsToBeBound = if instanceEvents
      eventsToBeBound = defaultEvents.trim().split(" ")
      instanceEvents  = instanceEvents.trim().split(" ")
      for event in instanceEvents
        eventsToBeBound.push event unless event in eventsToBeBound
      eventsToBeBound.join(" ")
    else
      defaultEvents

    $elm.bind eventsToBeBound, (event)=>
      willPropagateToDOM = @handleEvent event
      event.stopPropagation() unless willPropagateToDOM
      yes

    # if @contextMenu?
    #   $elm.bind "contextmenu",(event)=>
    #     @handleEvent event

    eventsToBeBound

  handleEvent:(event)->
    methodName = eventToMethodMap()[event.type] or event.type
    result     = if @[methodName]? then @[methodName] event else yes

    unless result is no
      @emit event.type, event
      # deprecate below 09/2012 sinan
      @propagateEvent (KDEventType:event.type.capitalize()),event
      @propagateEvent (KDEventType:((@inheritanceChain method:"constructor.name",callback:@chainNames).replace /\.|$/g,"#{event.type.capitalize()}."), globalEvent : yes),event
    willPropagateToDOM = result

  scroll:(event)->     yes

  error:(event)->      yes

  keyUp:(event)->      yes

  keyDown:(event)->    yes

  keyPress:(event)->   yes

  dblClick:(event)->   yes

  click:(event)->
    @hideTooltip()
    yes

  contextMenu:(event)->yes

  mouseMove:(event)->  yes

  mouseEnter:(event)-> yes

  mouseLeave:(event)-> yes

  mouseUp:(event)->    yes

  paste:(event)->      yes

  mouseDown:(event)->
    (@getSingleton "windowController").setKeyView null
    yes

  # HTML5 DND
  dragEnter:(e)->

    e.preventDefault()
    e.stopPropagation()

  dragOver:(e)->

    e.preventDefault()
    e.stopPropagation()

  dragLeave:(e)->

    e.preventDefault()
    e.stopPropagation()

  drop:(event)->

    event.preventDefault()
    event.stopPropagation()
    # no

  submit:(event)-> no #propagations leads to window refresh

  addEventHandlers:(options)->
    for eventName, cb of options
      if eventNames.test(eventName) and "function" is typeof cb
        @on eventName, cb

  setDraggable:(options = {})->

    options = {} if options is yes

    @dragState =
      containment : options.containment             # a parent KDView
      handle      : options.handle                  # a parent KDView or a child selector
      axis        : options.axis                    # a String 'x' or 'y' or 'diagonal'

    handle = if options.handle and options.handle instanceof KDView then handle else @

    handle.on "mousedown", (event)=>
      if "string" is typeof options.handle
        return if $(event.target).closest(options.handle).length is 0

      @dragIsAllowed = yes

      top    = parseInt @$()[0].style.top, 10
      right  = parseInt @$()[0].style.right, 10
      bottom = parseInt @$()[0].style.bottom, 10
      left   = parseInt @$()[0].style.left, 10

      @dragState.startX     = event.pageX
      @dragState.startY     = event.pageY
      @dragState.top        = top
      @dragState.right      = right
      @dragState.bottom     = bottom
      @dragState.left       = left

      @dragState.directionX = unless isNaN left then "left" else "right"
      @dragState.directionY = unless isNaN top  then "top"  else "bottom"

      @getSingleton('windowController').setDragView @
      @emit "DragStarted", event, @dragState
      event.stopPropagation()
      event.preventDefault()
      return no

  drag:(event, delta)->

    {directionX, directionY, axis} = @dragState
    {x, y} = delta

    y    = -y if directionY is "bottom"
    x    = -x if directionX is "right"
    posY = @dragState[directionY] + y
    posX = @dragState[directionX] + x

    if @dragIsAllowed
      @$().css directionX, posX unless axis is 'y'
      @$().css directionY, posY unless axis is 'x'

    @emit "DragInAction", x, y

# #
# VIEW READY EVENTS
# #

  viewAppended:()->

  childAppended:(child)->
    # bubbling childAppended event
    @parent?.emit 'childAppended', child

  setViewReady:()->
    @viewIsReady = yes

  isViewReady:()->
    @viewIsReady or no

# #
# HELPER METHODS
# #

  putOverlay:(options = {})->

    {isRemovable, cssClass, parent, animated, color} = options

    isRemovable ?= yes
    cssClass    ?= "transparent"
    parent      ?= "body"           #body or a KDView instance

    @$overlay = $ "<div />", class : "kdoverlay #{cssClass} #{if animated then "animated"}"

    if color
      @$overlay.css "background-color" : color

    if "string" is typeof parent
      @$overlay.appendTo $(parent)
    else if parent instanceof KDView
      @__zIndex = parseInt(@$().css("z-index"), 10) or 0
      @$overlay.css "z-index", @__zIndex + 1
      @$overlay.appendTo parent.$()

    if animated
      @utils.wait =>
        @$overlay.addClass "in"
      @utils.wait 300, =>
        @emit "OverlayAdded", @
    else
      @emit "OverlayAdded", @

    if isRemovable
      @$overlay.on "click.overlay", @removeOverlay.bind @

  removeOverlay:()->

    return unless @$overlay

    @emit "OverlayWillBeRemoved"
    kallback = =>
      @$overlay.off "click.overlay"
      @$overlay.remove()
      delete @__zIndex
      delete @$overlay
      @emit "OverlayRemoved", @

    if @$overlay.hasClass "animated"
      @$overlay.removeClass "in"
      @utils.wait 300, =>
        kallback()
    else
      kallback()

  setTooltip:(o = {})->

    placementMap =
      above      : "s"
      below      : "n"
      left       : "e"
      right      : "w"

    o.title     or= ""
    o.placement or= "above"
    o.offset    or= 0
    o.delayIn   or= 300
    o.delayOut  or= 300
    o.html      or= yes
    o.animate   or= no
    o.opacity   or= 0.9
    o.selector  or= null
    o.engine    or= "tipsy" # we still can use twipsy
    o.gravity   or= placementMap[o.placement]
    o.fade      or= o.animate
    o.fallback  or= o.title
    o.view      or= null
    o.viewCssClass or= null

    @on "viewAppended", =>
      # log "get rid of this timeout there should be an event after template update"
      @utils.wait =>

        # tooltips that are just strings will be handled by t(w)ipsy
        unless o.view
          @$(o.selector)[o.engine] o
        else

          # tooltips that provide a view will add their view + container
          # to the dom on first hover and reuse that view from then on

          # it will only be added to the DOM once
          @isFirstTooltip = yes

          @$(o.selector).hover =>

            # bridge variables for the mouse movement from the selector
            # towards and onto the tooltip
            @hasLeftSelector = no
            @hasMovedToTooltip = no

            # preparation is either adding to DOM or just reusing the
            # prepared view
            @prepareTooltip o, @isFirstTooltip, =>

              # after adding to DOM, prevent further additions of the same
              # view
              @isFirstTooltip = no
          , =>
            @hasLeftSelector = yes

            # give the user some time to focus the tooltip
            setTimeout =>
              if not @hasMovedToTooltip
                if o.fade
                  @tooltipViewContainer?.$().fade o.delayOut, =>
                    @tooltipViewContainer?.hide()
                else
                  @tooltipViewContainer?.hide()
            ,500

  prepareTooltip:(o = {}, isFirstTooltip = no, callback = noop)->

    if isFirstTooltip
      @tooltipViewContainer = new KDView
        cssClass : 'tooltip-container hidden'
      if o.viewCssClass
        @tooltipViewContainer.setClass o.viewCssClass
      @tooltipWrapper = new KDView
        cssClass : 'tooltip-wrapper'
      @tooltipArrowBelow = new KDView
        cssClass : 'tooltip-arrow-below'
      @tooltipArrowAbove = new KDView
        cssClass : 'tooltip-arrow-above'

      @tooltipWrapper.addSubView o.view
      @tooltipViewContainer.addSubView @tooltipArrowAbove
      @tooltipViewContainer.addSubView @tooltipWrapper
      @tooltipViewContainer.addSubView @tooltipArrowBelow
      @getSingleton('mainView').addSubView @tooltipViewContainer

    callback() # now that the view is in the DOM, prevent further insertion

    setTimeout =>

      # prevent instant popup when just moving/scrolling
      unless @hasLeftSelector
        @tooltipViewContainer.show()

        # measure the distance for proper placement
        container = @tooltipViewContainer.$()
        containerHeight = container.height()
        containerWidth = container.width()
        selector = @$(o.selector)
        selectorOffset = selector.offset()
        selectorHeight = selector.height()
        selectorWidth = selector.width()

        # vertical placement defaults to above, so only paint below the
        # selector if specifically demanded or if there is not enough space
        if o.placement is 'below' or (o.placement is 'above' and selectorOffset.top-selectorHeight-containerHeight < 0)
          @tooltipViewContainer.setClass 'painted-below'
          @tooltipViewContainer.unsetClass 'painted-above'
          container.css top : selectorOffset.top+selectorHeight+10
        else
          @tooltipViewContainer.setClass 'painted-above'
          @tooltipViewContainer.unsetClass 'painted-below'
          container.css top : selectorOffset.top-containerHeight-10

        # horizontal placement defaults to right, will only paint left if
        # there is enough space for it.
        if o.placement is 'left' or ( selectorOffset.left+containerWidth > window.innerWidth)
          @tooltipViewContainer.setClass 'painted-left'
          @tooltipViewContainer.unsetClass 'painted-right'
          container.css left : selectorOffset.left-containerWidth+selectorWidth
        else
          @tooltipViewContainer.setClass 'painted-right'
          @tooltipViewContainer.unsetClass 'painted-left'
          container.css left : selectorOffset.left

        @tooltipViewContainer.$().hover =>
          @hasMovedToTooltip = yes
        ,=>
          @tooltipViewContainer.hide()
    ,o.delayIn

  getTooltip:(o = {})->
    o.selector or= null
    return @$(o.selector)[0].getAttribute "original-title" or @$(o.selector)[0].getAttribute "title"

  updateTooltip:(o = {})->
    o.selector or= null
    o.title    or= ""
    @$(o.selector)[0].setAttribute "original-title", o.title
    @$(o.selector).tipsy "update"

  hideTooltip:(o = {})->
    o.selector or= null
    @$(o.selector).tipsy "hide"
    @tooltipViewContainer?.hide()

  listenWindowResize:->

    @getSingleton('windowController').registerWindowResizeListener @


  notifyResizeListeners:->

    @getSingleton('windowController').notifyWindowResizeListeners()

  setKeyView:->

    @getSingleton("windowController").setKeyView @


# #
# DEPRECATED METHODS
# #
  getParentDomElement:()->deprecated "KDView::getParentDomElement"



