###
todo:

  - make addLayer implementation more clear, by default adding a layer
    should set a listener for next ReceivedClickElsewhere and remove the layer automatically
    2012/5/21 Sinan

###
class KDWindowController extends KDController

  @keyViewHistory = []

  constructor:(options,data)->
    @windowResizeListeners = {}
    @keyView
    @dragView
    @scrollingEnabled = yes
    @bindEvents()
    @setWindowProperties()
    super

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

    $(window).bind "keydown keyup keypress",@key

    # document.body.addEventListener "keydown",  (event)=> @key event , yes
    # document.body.addEventListener "keyup",    (event)=> @key event , yes
    # document.body.addEventListener "keypress", (event)=> @key event , yes

    $(window).bind "resize",(event)=>
      @setWindowProperties event
      @notifyWindowResizeListeners event

    document.body.addEventListener "dragenter", (event)=>
      unless @dragInAction
        @propagateEvent (KDEventType: 'DragEnterOnWindow'), event
        @setDragInAction yes
    , yes

    document.body.addEventListener "dragleave", (event)=>
      unless 0 < event.clientX < @winWidth and
             0 < event.clientY < @winHeight
        @propagateEvent (KDEventType: 'DragExitOnWindow'), event
        @setDragInAction no
    , yes

    document.body.addEventListener "drop", (event)=>
      @propagateEvent (KDEventType: 'DragExitOnWindow'), event
      @propagateEvent (KDEventType: 'DropOnWindow'), event
      @setDragInAction no
    , yes

    @layers = layers = []

    document.body.addEventListener 'mousedown', (e)=>
      $('.twipsy').remove() # temporary for beta
      lastLayer = layers[layers.length-1]

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

    # unless window.location.hostname is 'localhost'
    window.onbeforeunload = (event) =>
      # fixme: fix this with appmanager
      for pane in @getSingleton('mainView').mainTabView.panes
        if pane.getOptions().type is "application" and pane.getOptions().name isnt "New Tab"
          event or= window.event
          msg = "Please make sure that you saved all your work."
          event.returnValue = msg if event # For IE and Firefox prior to version 4
          return msg

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

  setKeyView:(newKeyView)->

    return if newKeyView is @keyView
    # debugger
    # unless newKeyView
    #   debugger
    # log newKeyView, "newKeyView" if newKeyView

    @oldKeyView = @keyView
    @keyView = newKeyView

    @constructor.keyViewHistory.push newKeyView

    newKeyView?.emit 'KDViewBecameKeyView'
    @emit 'WindowChangeKeyView', newKeyView

  setDragView:(dragView)->

    @setDragInAction yes
    @dragView = dragView

  unsetDragView:(e)->

    @setDragInAction no
    @dragView.emit "DragFinished", e, @dragState
    @dragView = null


  redirectMouseMoveEvent:(event)->

    view = @dragView

    {pageX, pageY}   = event
    {startX, startY} = view.dragState

    delta =
      x : pageX - startX
      y : pageY - startY

    view.drag event, delta

  getKeyView:()->
    @keyView

  key:(event)=>
    # log event.type, @keyView.constructor.name, @keyView.getOptions().name
    @keyView?.handleEvent event

  allowScrolling:(shouldAllowScrolling)->
    @scrollingEnabled = shouldAllowScrolling

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
