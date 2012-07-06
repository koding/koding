class ContentDisplayController extends KDController
  constructor:(options)->
    super options
    @displays = {}
    @attachListeners()
    @lastShownViewDataId = null
    @lastShownViewConstructorName = null

  attachListeners:->
    @registerListener
      KDEventTypes  : "ContentDisplayWantsToBeShown"
      listener      : @
      callback      : (pubInst,view)=>
        @showContentDisplay view

    @registerListener
      KDEventTypes  : "ContentDisplayWantsToBeHidden"
      listener      : @
      callback      : (pubInst,view)=>
        @hideContentDisplay view

    appManager.registerListener
      KDEventTypes  : "ApplicationShowedAView"
      listener      : @
      callback      : =>
        @hideAllContentDisplays()

    @registerListener
      KDEventTypes  : "ContentDisplaysShouldBeHidden"
      listener      : @
      callback      : =>
        @hideAllContentDisplays()

  showContentDisplay:(view)->
    log "View: ", view.constructor.name
    ###
    if view.getData().getId?() is @lastShownViewDataId and
       view.constructor.name is @lastShownViewConstructorName
      new KDNotificationView
        title      : "Already in this!"
        type       : "mini"
      return
    ###
    contentPanel = @getSingleton "contentPanel"
    wrapper = new ContentDisplay
    @displays[view.id] = view
    wrapper.addSubView view
    contentPanel.addSubView wrapper

    # @lastShownViewDataId = view.getData().getId?()
    # @lastShownViewConstructorName = view.constructor.name

    @slideWrapperIn wrapper

  hideContentDisplay:(view)->
    @slideWrapperOut view

  hideAllContentDisplays:->
    displayIds = (id for id,display of @displays)
    return if displayIds.length is 0

    lastId = displayIds.pop()
    for id in displayIds
      @destroyView @displays[id]

    @slideWrapperOut @displays[lastId]

  slideWrapperIn:(wrapper)->
    wrapper.$().animate left : "0%",200

  slideWrapperOut:(view)->
    wrapper = view.parent
    wrapper.$().animate left : "100%",100,=>
      @destroyView view

  destroyView:(view)->
    wrapper = view.parent
    delete @displays[view.id]
    view.destroy()
    wrapper.destroy()
