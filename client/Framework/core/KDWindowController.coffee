###
todo:

  - make addLayer implementation more clear, by default adding a layer
    should set a listener for next ReceivedClickElsewhere and remove the layer automatically
    2012/5/21 Sinan

###

class KDWindowController extends KDController

  @keyViewHistory = []
  superKey        = if navigator.userAgent.indexOf("Mac OS X") is -1 then "ctrl" else "command"
  addListener     = (eventName, listener, capturePhase=yes)->
    document.body.addEventListener eventName, listener, capturePhase

  # Finding vendor prefixes for visibility
  getVisibilityProperty = ->
    prefixes = ["webkit", "moz", "o"]
    return "hidden" if `"hidden" in document`
    return "#{prefix}Hidden" for prefix in prefixes when `prefix + "Hidden" in document`
    return ""

  isFocused = -> Boolean document[getVisibilityProperty()]

  getVisibilityEventName = ->
    return "#{getVisibilityProperty().replace(/[Hh]idden/, '')}visibilitychange"

  constructor:(options,data)->

    @windowResizeListeners = {}
    @keyEventsToBeListened = ['keydown', 'keyup', 'keypress']
    @currentCombos         = {}
    @keyView               = null
    @dragView              = null
    @scrollingEnabled      = yes
    @layers                = []
    @unloadListeners       = {}
    @focusListeners        = []

    @bindEvents()
    @setWindowProperties()

    super options, data

  addLayer: (layer)->

    unless layer in @layers
      # log "layer added", layer
      @layers.push layer
      layer.on 'KDObjectWillBeDestroyed', =>
        @removeLayer layer

  removeLayer: (layer)->

    if layer in @layers
      # log "layer removed", layer
      index = @layers.indexOf(layer)
      @layers.splice index, 1

  bindEvents:->

    $(window).bind @keyEventsToBeListened.join(' '), @bound "key"

    $(window).bind "resize",(event)=>
      @setWindowProperties event
      @notifyWindowResizeListeners event

    addListener "dragenter", (event)=>
      unless @dragInAction
        @emit 'DragEnterOnWindow', event
        @setDragInAction yes

    addListener "dragleave", (event)=>
      unless 0 < event.clientX < @winWidth and
             0 < event.clientY < @winHeight
        @emit 'DragExitOnWindow', event
        @setDragInAction no

    addListener "drop", (event)=>
      @emit 'DragExitOnWindow', event
      @emit 'DropOnWindow', event
      @setDragInAction no

    layers = @layers

    addListener 'mousedown', (e)=>
      # $('.twipsy').remove() # temporary for beta
      lastLayer = layers.last

      if lastLayer and $(e.target).closest(lastLayer?.$()).length is 0
        # log lastLayer, "ReceivedClickElsewhere"
        lastLayer.emit 'ReceivedClickElsewhere', e
        @removeLayer lastLayer

    addListener 'mouseup', (e)=>
      @unsetDragView e if @dragView
      @emit 'ReceivedMouseUpElsewhere', e

    addListener 'mousemove', (e)=>
      @redirectMouseMoveEvent e if @dragView

    # internal links (including "#") should prevent default, so we don't end
    # up with duplicate entries in history: e.g. /Activity and /Activity#
    # also so that we don't redirect the browser
    addListener 'click', (e)->
      isInternalLink = e.target?.nodeName.toLowerCase() is 'a' and\           # html nodenames are uppercase, so lowercase this.
                       e.target.target?.length is 0                           # targeted links should work as normal.
                       # e.target.target isnt '_blank'                        # target _blank links should work as normal.
      if isInternalLink
        e.preventDefault()
        href = $(e.target).attr 'href'
        if href and not /^#/.test href
          KD.getSingleton('router').handleRoute href

    window.addEventListener 'beforeunload', @bound "beforeUnload"

    # TODO: this is a kludge we needed.  sorry for this.  Move it someplace better C.T.
    @utils.wait 15000, =>
      KD.remote.api.JSystemStatus.on 'forceReload', =>
        window.removeEventListener 'beforeunload', @bound 'beforeUnload'
        location.reload()

    @utils.repeat 1000, do (cookie = $.cookie 'clientId') => =>
      if cookie? and cookie isnt $.cookie 'clientId'
        window.removeEventListener 'beforeunload', @bound 'beforeUnload'
        @emit "clientIdChanged"
        @utils.defer -> window.location.replace '/'
      cookie = $.cookie 'clientId'

    document.addEventListener getVisibilityEventName(), (event)=>
      @focusChange event, isFocused()

  addUnloadListener:(key, listener)->
    listeners = @unloadListeners[key] or= []
    listeners.push listener

  clearUnloadListeners: (key)->
    if key
      @unloadListeners[key] = []
    else
      @unloadListeners = {}

  addFocusListener: (listener)-> @focusListeners.push listener

  focusChange: (event, state)->

    return unless event
    listener state, event for listener in @focusListeners

  beforeUnload:(event)->

    return unless event

    # all the listeners make their checks if it is safe or not to reload the page
    # they either return true or false if any of them returns false we intercept reload

    for key, listeners of @unloadListeners
      for listener in listeners
        if listener() is off
          message = unless key is "window" then " on #{key}" else ""
          return "Please make sure that you saved all your work#{message}."

  setDragInAction:(@dragInAction = no)->
    $('body')[if @dragInAction then "addClass" else "removeClass"] "dragInAction"

  setMainView:(@mainView)->

  getMainView:(view)-> @mainView

  revertKeyView:(view)->

    unless view
      warn "you must pass the view as a param, which doesn't want to be keyview anymore!"
      return

    if view is @keyView and @keyView isnt @oldKeyView
      @setKeyView @oldKeyView

  superizeCombos = (combos)->

    safeCombos = {}
    for combo, cb of combos
      if /\bsuper(\+|\s)/.test combo
        combo = combo.replace /super/g, superKey
      safeCombos[combo] = cb

    return safeCombos

  viewHasKeyCombos:(view)->

    return unless view

    o      = view.getOptions()
    combos = {}

    for e in @keyEventsToBeListened
      if "object" is typeof o[e]
        for combo, cb of o[e]
          combos[combo] = cb

    return if Object.keys(combos).length > 0 then combos else no

  registerKeyCombos:(view)->

    if combos = @viewHasKeyCombos view
      view.setClass "mousetrap"
      @currentCombos = superizeCombos combos
      for combo, cb of @currentCombos
        Mousetrap.bind combo, cb, 'keydown'

  unregisterKeyCombos:->

    @currentCombos = {}
    Mousetrap.reset()
    @keyView.unsetClass "mousetrap" if @keyView

  setKeyView:(newKeyView)->

    return if newKeyView is @keyView
    # unless newKeyView
    # log newKeyView, "newKeyView" if newKeyView

    @unregisterKeyCombos()
    @oldKeyView = @keyView
    @keyView    = newKeyView
    @registerKeyCombos newKeyView

    @constructor.keyViewHistory.push newKeyView

    newKeyView?.emit 'KDViewBecameKeyView'
    @emit 'WindowChangeKeyView', newKeyView

  setDragView:(dragView)->

    @setDragInAction yes
    @dragView = dragView

  unsetDragView:(e)->

    @setDragInAction no
    @dragView.emit "DragFinished", e
    @dragView = null


  redirectMouseMoveEvent:(event)->

    view = @dragView

    {pageX, pageY}   = event
    {initial}        = view.dragState.position
    initialX         = initial.x
    initialY         = initial.y

    delta =
      x : pageX - initialX
      y : pageY - initialY

    view.drag event, delta

  getKeyView:-> @keyView

  key:(event)->
    # log event.type, @keyView.constructor.name, @keyView.getOptions().name
    # if Object.keys(@currentCombos).length > 0
    #   return yes
    # else
    @emit event.type, event
    @keyView?.handleEvent event

  enableScroll:-> @scrollingEnabled = yes

  disableScroll:-> @scrollingEnabled = no

  registerWindowResizeListener:(instance)->
    @windowResizeListeners[instance.id] = instance
    instance.on "KDObjectWillBeDestroyed", =>
      delete @windowResizeListeners[instance.id]

  unregisterWindowResizeListener:(instance)->
    delete @windowResizeListeners[instance.id]

  setWindowProperties:(event)->
    @winWidth  = window.innerWidth
    @winHeight = window.innerHeight

  notifyWindowResizeListeners:(event, throttle = no, duration = 17)->
    event or= type : "resize"
    fireResizeHandlers = =>
      for key, instance of @windowResizeListeners when instance._windowDidResize
        instance._windowDidResize event
    if throttle
      KD.utils.killWait @resizeNotifiersTimer
      @resizeNotifiersTimer = KD.utils.wait duration, fireResizeHandlers
    else do fireResizeHandlers