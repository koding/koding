class ContentDisplayController extends KDController

  constructor:(options)->

    super

    @displays = {}
    @attachListeners()


  attachListeners:->

    mc         = KD.singleton 'mainController'
    appManager = KD.singleton 'appManager'
    @on "ContentDisplayWantsToBeShown",  (view)=> mc.ready => @showDisplay view
    @on "ContentDisplayWantsToBeHidden", (view)=> mc.ready => @hideDisplay view
    @on "ContentDisplaysShouldBeHidden",       => mc.ready => @hideAllDisplays()
    appManager.on "ApplicationShowedAView",    => mc.ready => @hideAllDisplays()


  showDisplay:(view)->

    tabPane = new ContentDisplay
      name  : 'content-display'
      type  : 'social'
      view  : view

    tabPane.on 'KDTabPaneInactive', => @hideDisplay view

    @displays[view.id] = view

    {@mainTabView} = KD.singleton "mainView"
    activePane = @mainTabView.getActivePane()
    @mainTabView.addPane tabPane

    model = view.getData()
    @changePageTitle model

    return tabPane


  changePageTitle:(model)->

    return  unless model

    {JAccount, SocialMessage, JGroup} = KD.remote.api
    title = switch model.constructor
      when JAccount          then  KD.utils.getFullnameFromAccount model
      when SocialMessage     then  @utils.getPlainActivityBody model
      when JGroup            then  model.title
      else "#{model.title}#{getSectionName model}"

    @utils.shortenText title, maxLength : 100 # max char length of the title

    KD.singletons.router.setPageTitle title


  hideDisplay:(view)->

    # KD.getSingleton('router').back()
    tabPane = view.parent
    @destroyView view
    @mainTabView.removePane tabPane  if tabPane


  hideAllDisplays:(exceptFor)->

    displayIds =\
      if exceptFor?
      then (id for own id,display of @displays when exceptFor isnt display)
      else (id for own id,display of @displays)

    return if displayIds.length is 0

    lastId = displayIds.pop()
    @destroyView @displays[id] for id in displayIds

    @hideDisplay @displays[lastId]


  destroyView:(view)->

    @emit 'DisplayIsDestroyed', view
    delete @displays[view.id]
    view.destroy()
