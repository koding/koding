###
todo:

  - make addLayer implementation more clear, by default adding a layer
    should set a listener for next ReceivedClickElsewhere and remove the layer automatically
    2012/5/21 Sinan

###

class KDWindowController extends KDController

  @keyViewHistory = []
  superKey        = if navigator.userAgent.indexOf("Mac OS X") is -1 then "ctrl" else "command"

  constructor:(options,data)->

    @windowResizeListeners = {}
    @keyEventsToBeListened = ['keydown', 'keyup', 'keypress']
    @currentCombos         = {}
    @keyView               = null
    @dragView              = null
    @scrollingEnabled      = yes

    @bindEvents()
    @setWindowProperties()

    super options, data

    KD.registerSingleton "windowController", @, yes

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

  bindEvents:()->

    $(window).bind @keyEventsToBeListened.join(' '), @bound "key"

    $(window).bind "resize",(event)=>
      @setWindowProperties event
      @notifyWindowResizeListeners event

    document.body.addEventListener "dragenter", (event)=>
      unless @dragInAction
        @emit 'DragEnterOnWindow', event
        @setDragInAction yes
    , yes

    document.body.addEventListener "dragleave", (event)=>
      unless 0 < event.clientX < @winWidth and
             0 < event.clientY < @winHeight
        @emit 'DragExitOnWindow', event
        @setDragInAction no
    , yes

    document.body.addEventListener "drop", (event)=>
      @emit 'DragExitOnWindow', event
      @emit 'DropOnWindow', event
      @setDragInAction no
    , yes

    @layers = layers = []

    document.body.addEventListener 'mousedown', (e)=>
      # $('.twipsy').remove() # temporary for beta
      lastLayer = layers.last

      if lastLayer and $(e.target).closest(lastLayer?.$()).length is 0
        # log lastLayer, "ReceivedClickElsewhere"
        lastLayer.emit 'ReceivedClickElsewhere', e
        @removeLayer lastLayer
    , yes

    document.body.addEventListener 'mouseup', (e)=>
      @unsetDragView e if @dragView
      @emit 'ReceivedMouseUpElsewhere', e
    , yes

    document.body.addEventListener 'mousemove', (e)=>
      @redirectMouseMoveEvent e if @dragView
    , yes

    # internal links (including "#") should prevent default, so we don't end
    # up with duplicate entries in history: e.g. /Activity and /Activity#
    # also so that we don't redirect the browser
    document.body.addEventListener 'click', (e)->
      isInternalLink = e.target?.nodeName.toLowerCase() is 'a' and\   # html nodenames are uppercase, so lowercase this.
                       e.target.target?.length is 0                      # targeted links should work as normal.
                       # e.target.target isnt '_blank'                  # target _blank links should work as normal.
      if isInternalLink
        e.preventDefault()
        href = $(e.target).attr 'href'
        if href and not /^#/.test href
          KD.getSingleton('router').handleRoute href
    , yes

    # unless window.location.hostname is 'localhost'
    window.addEventListener 'beforeunload', @bound "beforeUnload"

  beforeUnload:(event)->
    # fixme: fix this with appmanager

    # if @getSingleton('mainView')?.mainTabView?.panes
    #   for pane in @getSingleton('mainView').mainTabView.panes
    #     msg = no

    #     # For open Tabs (apps, editors)
    #     if pane.getOptions().type is "application" and pane.getOptions().name isnt "New Tab"
    #       msg = "Please make sure that you saved all your work."

    #     # This cssClass needs to be added to the KDInputView OR
    #     # a shadow KDInputView
    #     pane.data.$(".warn-on-unsaved-data").each (i,element) =>


    #       # If the View is a KDInputview, we don"t need to look
    #       # further than the .val(). For ACE and others, we have
    #       # to implement content shadowing in the widgets/inputs
    #       if $(element).hasClass("kdinput") and $(element).val()
    #         msg = "You may lose some input that you filled in."


    # if msg # has to be created in the above checks
    #   event or= window.event
    #   event.returnValue = msg if event # For IE and Firefox prior to version 4
    #   return msg



  setDragInAction:(action = no)->

    $('body')[if action then "addClass" else "removeClass"]("dragInAction")
    @dragInAction = action

  setMainView:(view)->
    @mainView = view

  getMainView:(view)->
    @mainView

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

  getKeyView:()->
    @keyView

  key:(event)->
    # log event.type, @keyView.constructor.name, @keyView.getOptions().name
    # if Object.keys(@currentCombos).length > 0
    #   return yes
    # else
    @keyView?.handleEvent event

  enableScroll:->
    @scrollingEnabled = yes

  disableScroll:->
    @scrollingEnabled = no

  registerWindowResizeListener:(instance)->
    @windowResizeListeners[instance.id] = instance
    instance.on "KDObjectWillBeDestroyed", =>
      delete @windowResizeListeners[instance.id]

  setWindowProperties:(event)->
    @winWidth  = $(window).width()
    @winHeight = $(window).height()

  notifyWindowResizeListeners:(event, throttle = no, duration = 17)->
    event or= type : "resize"
    if throttle
      clearTimeout @resizeNotifiersTimer if @resizeNotifiersTimer
      @resizeNotifiersTimer = setTimeout ()=>
        for key,instance of @windowResizeListeners
          instance._windowDidResize? event
      , duration
    else
      for key,instance of @windowResizeListeners
        instance._windowDidResize? event

  # notifyWindowResizeListeners: __utils.throttle (event)=>
  #   event or= type : "resize"
  #   for key,instance of @windowResizeListeners
  #     instance._windowDidResize? event
  # ,50

new KDWindowController