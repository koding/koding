class ContentDisplayController extends KDController

  constructor:(options)->
    super
    @displays = {}
    @attachListeners()

  attachListeners:->
    @on "ContentDisplayWantsToBeShown",  (view)=> @showContentDisplay view
    @on "ContentDisplayWantsToBeHidden", (view)=> @hideContentDisplay view
    @on "ContentDisplaysShouldBeHidden",       => @hideAllContentDisplays()
    KD.getSingleton("appManager").on "ApplicationShowedAView",    => @hideAllContentDisplays()

  showContentDisplay:(view, callback=->)->
    contentPanel = @getSingleton "contentPanel"
    wrapper = new ContentDisplay
    @displays[view.id] = view
    wrapper.addSubView view
    contentPanel.addSubView wrapper
    @slideWrapperIn wrapper
    callback wrapper

  hideContentDisplay:(view)-> history.back()

  hideAllContentDisplays:(exceptFor)->
    displayIds =\
      if exceptFor?
        (id for own id,display of @displays when exceptFor isnt display)
      else
        (id for own id,display of @displays)

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
    @emit 'ContentDisplayIsDestroyed', view
    delete @displays[view.id]
    view.destroy()
    wrapper.destroy()
