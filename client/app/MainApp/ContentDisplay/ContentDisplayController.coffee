class ContentDisplayController extends KDController

  constructor:(options)->
    super
    @displays = {}
    @attachListeners()

  attachListeners:->
    @on "ContentDisplayWantsToBeShown",  (view)=> @showContentDisplay view
    @on "ContentDisplayWantsToBeHidden", (view)=> @hideContentDisplay view
    @on "ContentDisplaysShouldBeHidden",       => @hideAllContentDisplays()
    appManager.on "ApplicationShowedAView",    => @hideAllContentDisplays()

  showContentDisplay:(view)->
    contentPanel = @getSingleton "contentPanel"
    wrapper = new ContentDisplay
    @displays[view.id] = view
    wrapper.addSubView view
    contentPanel.addSubView wrapper
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
