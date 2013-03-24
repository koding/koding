class FeederResultsController extends KDViewController

  constructor:(options = {}, data)->

    options.view                or= new FeederTabView hideHandleCloseIcons : yes
    options.paneClass           or= FeederTabPaneView
    options.itemClass           or= KDListItemView
    options.listControllerClass or= KDListViewController
    options.onboarding          or= null

    super options,data

    @panes = {}
    @listControllers = {}

    for name, filter of options.filters
      @createTab name,filter

  loadView:(mainView)->

    mainView.hideHandleContainer()
    mainView.showPaneByIndex 0
    @utils.defer mainView.bound "_windowDidResize"

  openTab:(filter, callback)->
    tabView = @getView()
    pane = tabView.getPaneByName filter.name
    tabView.showPane pane
    callback? @listControllers[filter.name]

  createTab:(name, filter, callback)->
    {
      paneClass
      itemClass
      listControllerClass
      listCssClass
      onboarding
    } = @getOptions()

    tabView = @getView()

    @listControllers[name] = listController = new listControllerClass
      lazyLoadThreshold   : .75
      startWithLazyLoader : yes
      noItemFoundText     : filter.noItemFoundText or null
      viewOptions         : {
        cssClass          : listCssClass
        type              : name
        itemClass
      }

    forwardItemWasAdded = @emit.bind this, 'ItemWasAdded'

    listController.getListView().on 'ItemWasAdded', forwardItemWasAdded

    listController.on 'LazyLoadThresholdReached', =>
      @emit "LazyLoadThresholdReached"

    tabView.addPane @panes[name] = pane = new paneClass
      name : name

    pane.addSubView pane.listHeader = header = new CommonListHeader
      title : filter.optional_title or filter.title

    pane.addSubView pane.listWrapper = listController.getView()

    if onboarding
      pane.onboarding = if onboarding[name] instanceof KDView
        onboarding[name]
      else if typeof onboarding[name] is "string"
        new FeederOnboardingView
          pistachio : onboarding[name]

      if pane.onboarding
        pane.onboarding.setOption "name", name
        pane.onboarding.hide()
        listController.getListView().addSubView pane.onboarding

        appManager = @getSingleton("appManager")
        app        = appManager.getFrontApp()
        app.appStorage?.fetchValue "onboardingMessageIsReadFor#{name.capitalize()}Tab", (value)=>
          unless value
            pane.onboarding.show()
            @utils.defer ->
              pane.onboarding.setClass 'in'

        pane.onboarding.on "OnboardingMessageCloseIconClicked", =>
          pane.onboarding.unsetClass 'in'
          @utils.wait 400, ->
            pane.onboarding.hide()

    listController.scrollView?.on 'scroll', (event) =>
      if event.delegateTarget.scrollTop > 0
        header.setClass "scrolling-up-outset"
      else
        header.unsetClass "scrolling-up-outset"

    callback? listController
