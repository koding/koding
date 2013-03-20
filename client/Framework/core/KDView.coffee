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
    error|
    load
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
    mousewheel  : "mouseWheel"
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
    o.tooltip     or= null      # an Object of kdtooltip options
    o.preserveValue or= null

    # TO BE IMPLEMENTED
    o.resizable   or= null      # TBDL
    super o,data

    data?.on? 'update', => @render()

    @setInstanceVariables options
    @defaultInit options,data

    @setClass 'kddraggable' if o.draggable

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

    # development only
    if location.hostname is "localhost"
      @on "click", (event)=>
        if event.metaKey and event.altKey and event.ctrlKey
          log @getData()
          event.stopPropagation?()
          event.preventDefault?()
          return false
        else if event.altKey and (event.metaKey or event.ctrlKey)
          log @
          return false

  setTemplate:(tmpl, params)->
    params ?= @getOptions()?.pistachioParams
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
    @setDomId options.domId               if options.domId
    @setDomAttributes options.attributes  if options.attributes
    @setSize options.size                 if options.size
    @setPosition options.position         if options.position
    @setPartial options.partial           if options.partial
    if options.preserveValue
      log 'preserving', options.preserveValue
      @setPreserveValue options.preserveValue

    @addEventHandlers options

    if options.pistachio
      @setTemplate options.pistachio, options.pistachioParams
      @template.update()

    @setLazyLoader options.lazyLoadThreshold  if options.lazyLoadThreshold

    @setTooltip options.tooltip      if options.tooltip
    @setDraggable options.draggable  if options.draggable

    @bindEvents()

# #
# VIEW PROPERTY GETTERS
# #

  getDomId:->
    @domElement.attr "id"


# #
# DOM ELEMENT CREATION
# #


  setDomElement:(cssClass='')->
    {lazyDomId, tagName} = @getOptions()

    el = document.getElementById lazyDomId  if lazyDomId

    unless el?
      warn "No lazy DOM Element found with given id #{lazyDomId}."  if lazyDomId
      el = document.createElement tagName

    for klass in "kdview #{cssClass}".split ' ' when klass.length
      el.classList.add klass

    @domElement = $ el

    if lazyDomId
      @utils.defer => @emit 'viewAppended'

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

  getDomElement:-> @domElement

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

  appendToSelector:(selector)->
    $(selector).append @$()
    @emit 'viewAppended', @

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

  prependToSelector:(selector)->
    $(selector).prepend @$()
    @emit 'viewAppended', @

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

  setWidth:(w, unit = "px")->
    @getElement().style.width = "#{w}#{unit}"
    # @getDomElement().width w
    @emit "ViewResized", {newWidth : w, unit}

  getHeight:()->
    # @getDomElement()[0].clientHeight
    @getDomElement().outerHeight(no)

  setHeight:(h)->
    @getElement().style.height = "#{h}px"
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

  destroy:->
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
    super

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
    view = @
    @on 'scroll', do ->
      lastRatio = 0
      (event)->
        el = view.$()[0]
        ratio = (el.scrollTop + view.getHeight()) / el.scrollHeight
        if ratio > lastRatio and ratio > threshold
          @emit 'LazyLoadThresholdReached', {ratio}
        lastRatio = ratio

  bindEvents:($elm)->
    $elm or= @getDomElement()
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

    eventsToBeBound

  bindEvent:($elm, eventName)->
    [eventName, $elm] = [$elm, @$()] unless eventName

    $elm.bind eventName, (event)=>
      shouldPropagate = @handleEvent event
      event.stopPropagation() unless shouldPropagate
      yes

  handleEvent:(event)->
    methodName      = eventToMethodMap()[event.type] or event.type
    shouldPropagate = if @[methodName]? then @[methodName] event else yes

    @emit event.type, event  unless shouldPropagate is no

    return shouldPropagate

  scroll:(event)->     yes

  load:(event)->       yes

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

  setEmptyDragState: ->
    @dragState =
      containment : null     # a parent KDView
      handle      : null     # a parent KDView or a child selector
      axis        : null     # a String 'x' or 'y' or 'diagonal'
      direction   :
        current   :
          x       : null     # a String 'left' or 'right'
          y       : null     # a String 'up'   or 'down'
        global    :
          x       : null     # a String 'left' or 'right'
          y       : null     # a String 'up'   or 'down'
      position    :
        relative  :
          x       : 0        # a Number
          y       : 0        # a Number
        initial   :
          x       : 0        # a Number
          y       : 0        # a Number
        global    :
          x       : 0        # a Number
          y       : 0        # a Number
      meta        :
        top       : 0        # a Number
        right     : 0        # a Number
        bottom    : 0        # a Number
        left      : 0        # a Number


  setDraggable:(options = {})->

    options = {} if options is yes

    @setEmptyDragState()
    handle = if options.handle and options.handle instanceof KDView then handle else @

    handle.on "mousedown", (event)=>
      if "string" is typeof options.handle
        return if $(event.target).closest(options.handle).length is 0

      @dragIsAllowed = yes
      @setEmptyDragState()

      dragState             = @dragState

      # TODO: should move these lines
      dragState.containment = options.containment
      dragState.handle      = options.handle
      dragState.axis        = options.axis

      dragMeta              = dragState.meta
      dragEl                = @$()[0]
      dragMeta.top          = parseInt(dragEl.style.top,    10) or 0
      dragMeta.right        = parseInt(dragEl.style.right,  10) or 0
      dragMeta.bottom       = parseInt(dragEl.style.bottom, 10) or 0
      dragMeta.left         = parseInt(dragEl.style.left,   10) or 0

      dragPos = @dragState.position
      dragPos.initial.x     = event.pageX
      dragPos.initial.y     = event.pageY

      @getSingleton('windowController').setDragView @
      @emit "DragStarted", event, @dragState
      event.stopPropagation()
      event.preventDefault()
      return no

  drag:(event, delta)->

    {directionX, directionY, axis} = @dragState

    {x, y}       = delta
    dragPos      = @dragState.position
    dragRelPos   = dragPos.relative
    dragInitPos  = dragPos.initial
    dragGlobPos  = dragPos.global
    dragDir      = @dragState.direction
    dragGlobDir  = dragDir.global
    dragCurDir   = dragDir.current

    if x > dragRelPos.x
      dragCurDir.x  = 'right'
    else if x < dragRelPos.x
      dragCurDir.x  = 'left'

    if y > dragRelPos.y
      dragCurDir.y  = 'bottom'
    else if y < dragRelPos.y
      dragCurDir.y  = 'top'

    dragGlobPos.x = dragInitPos.x + x
    dragGlobPos.y = dragInitPos.y + y

    dragGlobDir.x = if x > 0 then 'right'  else 'left'
    dragGlobDir.y = if y > 0 then 'bottom' else 'top'

    el = @$()
    if @dragIsAllowed
      dragMeta   = @dragState.meta
      targetPosX = if dragMeta.right  and not dragMeta.left then 'right'  else 'left'
      targetPosY = if dragMeta.bottom and not dragMeta.top  then 'bottom' else 'top'

      newX = if targetPosX is 'left' then dragMeta.left + dragRelPos.x else dragMeta.right  - dragRelPos.x
      newY = if targetPosY is 'top'  then dragMeta.top  + dragRelPos.y else dragMeta.bottom - dragRelPos.y

      el.css targetPosX, newX unless axis is 'y'
      el.css targetPosY, newY unless axis is 'x'

    dragRelPos.x = x
    dragRelPos.y = y

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
    o.placement or= "top"
    o.direction or= "center"
    o.offset    or=
      top         : 0
      left        : 0
    o.delayIn   or= 0
    o.delayOut  or= 0
    o.html      or= yes
    o.animate   or= no
    o.selector  or= null
    o.gravity   or= placementMap[o.placement]
    o.fade      or= o.animate
    o.fallback  or= o.title
    o.view      or= null
    o.delegate  or= @
    o.viewCssClass or= null
    o.showOnlyWhenOverflowing or= no # this will check for horizontal overflow

    isOverflowing = @$(o.selector)[0]?.offsetWidth < @$(o.selector)[0]?.scrollWidth
    if o.showOnlyWhenOverflowing and isOverflowing or not o.showOnlyWhenOverflowing
      @bindTooltipEvents o

  bindTooltipEvents:(o)->
    @bindEvent name for name in ['mouseenter','mouseleave']

    @on 'mouseenter',(event)=>
      if o.selector
        selectorEntered = no
        @bindEvent 'mousemove'

        @on 'mousemove', (mouseEvent)=>
          if $(mouseEvent.target).is(o.selector) and selectorEntered is no
            selectorEntered = yes
            @createTooltip o
            @tooltip?.emit 'MouseEnteredAnchor'
          if not $(mouseEvent.target).is(o.selector) and selectorEntered
            selectorEntered = no
            @tooltip?.emit 'MouseLeftAnchor'
      else
        return if o.selector and not $(event.target).is o.selector
        @createTooltip o
        @tooltip?.emit 'MouseEnteredAnchor'

    @on 'mouseleave', (event)=>
      return if o.seletor and not $(event.target).is o.selector
      @tooltip?.emit 'MouseLeftAnchor'
      @off 'mousemove'

  createTooltip:(o = {})->
    @tooltip ?= new KDTooltip o, {}

  getTooltip:(o = {})->
    if @tooltip?
      return @tooltip
    else
      o.selector or= null
      return @$(o.selector)[0].getAttribute "original-title" or @$(o.selector)[0].getAttribute "title"

  updateTooltip:(o = @getOptions().tooltip,view = null)->
    unless view
      o.selector or= null
      o.title    or= ""
      @getOptions().tooltip.title = o.title
      if @tooltip?
        @tooltip.setTitle o.title
        @tooltip.display @getOptions().tooltip
    else
      if @tooltip?
        @tooltip.setView view

  hideTooltip:(o = {})->
    o.selector or= null
    @tooltip?.hide()

  removeTooltip:(instance)->
    if instance
      @getSingleton('windowController').removeLayer instance
      instance.destroy()
      @tooltip = null
      delete @tooltip
    else
      log 'There was nothing to remove.'

  _windowDidResize:->

  listenWindowResize:->

    @getSingleton('windowController').registerWindowResizeListener @


  notifyResizeListeners:->

    @getSingleton('windowController').notifyWindowResizeListeners()

  setKeyView:->

    @getSingleton("windowController").setKeyView @

  setPreserveValue:(preserveValue={})->
    storedValue = @getSingleton('localStorageController').getValueById preserveValue.name

    if "string" is typeof preserveValue.saveEvents
      preserveValue.saveEvents = preserveValue.saveEvents.split(' ')
    if "string" is typeof preserveValue.clearEvents
      preserveValue.clearEvents = preserveValue.clearEvents.split(' ')

    for preserveEvent in preserveValue.saveEvents
      @on preserveEvent, (event)=>
        value = @getOptions().preserveValue.getValue?() ? @getValue?()
        @savePreserveValue preserveValue.name, value

    for preserveEvent in preserveValue.clearEvents
      @on preserveEvent, (event)=>
        @clearPreserveValue()

    if preserveValue.displayEvents then for displayEvent in preserveValue.displayEvents
      @on displayEvent, (event)=>
        @applyPreserveValue storedvalue if storedValue

    if storedValue
      @utils.defer => @applyPreserveValue storedValue


  applyPreserveValue:(value)->
    if @getOptions().preserveValue.setValue
      @getOptions().preserveValue.setValue value
    else @setValue? value

  savePreserveValue:(id,value)->
    @getSingleton('localStorageController').setValueById id, value

  clearPreserveValue:->
    if @getOptions().preserveValue
      @getSingleton('localStorageController').deleteId @getOptions().preserveValue.name

