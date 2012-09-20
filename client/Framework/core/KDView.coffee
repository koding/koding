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

  overrideAndMergeObjects = (objects)->
    for own title,item of objects.overridden
      continue if objects.overrider[title]
      objects.overrider[title] = item
    objects.overrider

  @appendToDOMBody = (view)->
    $("body").append view.$()
    view.parentIsInDom = yes
    view.propagateEvent KDEventType: 'viewAppended'

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

    data?.on? 'update', =>
      data
      @render()

    @setInstanceVariables options
    @defaultInit options,data

    if location.hostname is 'localhost'
      @listenTo
        KDEventTypes        : 'click'
        listenedToInstance  : @
        callback            : (publishingInstance, event)=>
          if event.metaKey and event.altKey and event.ctrlKey
            log @getData()
            event.stopPropagation?()
            event.preventDefault?()
            return false
          else if event.ctrlKey and event.altKey
            log @
            return false

    @listenTo
      KDEventTypes        : 'childAppended'
      listenedToInstance  : @
      callback            : (publishingInstance, child)=>
        @childAppended child

    @listenTo
      KDEventTypes        : 'viewAppended'
      listenedToInstance  : @
      callback            : =>
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
              child.propagateEvent KDEventType: 'viewAppended'
        else if type is "object"
          for key,child of subViews
            unless child.parentIsInDom
              child.parentIsInDom = yes
              child.propagateEvent KDEventType: 'viewAppended'


  setTemplate:(tmpl)->
    @template = new Pistachio(@, tmpl)
    @updatePartial @template.html
    @template.embedSubViews()

  pistachio:(tmpl)->
    "#{@options.prefix}#{tmpl}#{@options.suffix}"

  setParent:(parent)->
    if @parent?
      console.log "view:", @, "parent:", @parent
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
    child.propagateEvent KDEventType: 'viewAppended'

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
      @setTemplate options.pistachio
      @template.update()

    @setDelegate options.delegate                 if options.delegate
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
      child.propagateEvent KDEventType: 'viewAppended'
    @

  appendTo:(parent, selector)->
    @$().appendTo parent.$(selector)
    if @parentIsInDom
      @propagateEvent KDEventType: 'viewAppended'
    @

  prepend:(child, selector)->
    @$(selector).prepend child.$()
    if @parentIsInDom
      child.propagateEvent KDEventType: 'viewAppended'
    @

  prependTo:(parent, selector)->
    @$().prependTo parent.$(selector)
    if @parentIsInDom
      @propagateEvent KDEventType: 'viewAppended'
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
    # pre = Date.now()
    # w = @getDomElement()[0].clientWidth
    w = @getDomElement().width()
    # log Date.now() - pre,@,@id
    # w
  setWidth:(w)->
    @getDomElement()[0].style.width = "#{w}px"
    # @getDomElement().width w
    @emit "ViewResized", newWidth : w

  getHeight:()->
    # @getDomElement()[0].clientHeight
    @getDomElement().outerHeight()

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
      # log "parent subviews spliced"
      @parent.removeSubView @

    # instance removes itself from DOM
    @getDomElement().remove()

    if @$overlay?
      @removeOverlay()

    # call super to remove instance subscriptions
    # and delete instance from KD.instances registry
    super()
    # log delete @listeners
    # log delete @listeningTo

  destroySubViews:()->
    # (subView.destroy() for subView in @getSubViews())

    for subView in @getSubViews().slice()
      # log "ASDSD","asd"
      if subView instanceof KDView
        # log subView,subView.id.substring(0,5),"subView of:",@.id.substring(0,5)
        subView?.destroy?()
        # log delete subView.listeners
        # log delete subView.listeningTo

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
    defaultEvents = "mousedown mouseup click dblclick"
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
    # log event.type
    # thisEvent = @[event.type]? event or yes #this would be way awesomer than lines 98-103, but then we have to break camelcase convention in mouseUp, etc. names....??? worth it?
    thisEvent = switch event.type
      when "click"      then @click event
      when "dblclick"   then @dblClick event
      when "keyup"      then @keyUp event
      when "keydown"    then @keyDown event
      when "keypress"   then @keyPress event
      when "mouseup"    then @mouseUp event
      when "mousedown"  then @mouseDown event
      when "mouseenter" then @mouseEnter event
      when "mouseleave" then @mouseLeave event
      when "mousemove"  then @mouseMove event
      when "contextmenu"then @contextMenu event
     # when "dragstart"  then @dragStart event
      when "dragenter"  then @dragEnter event
      when "dragleave"  then @dragLeave event
      when "dragover"   then @dragOver event
      when "drop"       then @drop event
      when "scroll"     then @scroll event
      when "paste"      then @paste event
      # when "resize"     then @resize event
      when "blur"       then @blur event
      when "change"     then @change event
      when "focus"      then @focus event
      when "error"      then @error event
      else yes
    @propagateEvent (KDEventType:event.type.capitalize()),event if @notifiesOthers event
    @propagateEvent (KDEventType:((@inheritanceChain method:"constructor.name",callback:@chainNames).replace /\.|$/g,"#{event.type.capitalize()}."), globalEvent : yes),event if @notifiesOthers event
    willPropagateToDOM = thisEvent

  scroll:(event)->
    # log "override keyDown in your subclass to do something useful"
    yes

  error:(event)->
    # log "override keyDown in your subclass to do something useful"
    yes

  keyUp:(event)->
    # log "override keyDown in your subclass to do something useful"
    yes

  keyDown:(event)->
    # log "override keyDown in your subclass to do something useful"
    yes

  keyPress:(event)->
    yes

  dblClick:(event)->
    yes

  click:(event)->
    yes

  contextMenu:(event)->
    yes

  mouseMove:(event)->
    yes

  mouseUp:(event)->
    # log "override mouseUp in your subclass to do something useful"
    yes

  mouseDown:(event)->
    # log "override mouseDown in your subclass to do something useful"
    (@getSingleton "windowController").setKeyView null
    yes

  mouseEnter:(event)-> yes
  mouseLeave:(event)-> yes

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
    no

  submit:(event)->
    log "override submit in your subclass to do something useful"
    no #propagations leads to window refresh

  addEventHandlers:(options)->
    for key,value of options
      if eventNames.test key
        @listenTo
          KDEventTypes       : key
          listenedToInstance : @
          callback           : value

  setDraggable:(options = {})->

    options = {} if options is yes

    @dragState =
      containment : options.containment             # a parent KDView
      handle      : options.handle                  # a parent KDView or a child selector
      axis        : options.axis                    # a String 'x' or 'y' or 'diagonal'

    handle = if options.handle and options.handle instanceof KDView then handle else @

    @listenTo
      KDEventTypes       : "mousedown"
      listenedToInstance : handle
      callback           : (pubInst, event)=>

        if "string" is typeof options.handle
          return if $(event.target).closest(options.handle).length is 0

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
    @parent?.propagateEvent KDEventType: 'childAppended', child

  setViewReady:()->
    @viewIsReady = yes

  isViewReady:()->
    @viewIsReady or no

# #
# EVENT OPTION METHODS- subclasses can ovverride these methods to change defaults
# #

  notifiesOthers:(event)->#notifies the rest of the code when event happens?
    yes

  resignsKeyStatus:()->#allows click on other element to make them key instead of this one (i.e. is modal?)
    yes

  acceptsKeyStatus:()->#can become the key view
    yes

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
    o.html      or= yes
    o.animate   or= no
    o.opacity   or= 0.9
    o.selector  or= null
    o.engine    or= "tipsy" # we still can use twipsy
    o.gravity   or= placementMap[o.placement]
    o.fade      or= o.animate
    o.fallback  or= o.title

    @listenTo
      KDEventTypes        : "viewAppended"
      listenedToInstance  : @
      callback            : =>
        # log "get rid of this timeout there should be an event after template update"
        @utils.wait =>
          @$(o.selector)[o.engine] o

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



