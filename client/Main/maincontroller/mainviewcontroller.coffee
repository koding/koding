class MainViewController extends KDViewController

  constructor:->

    super

    {repeat, killRepeat} = KD.utils
    mainView             = @getView()
    appManager           = KD.singleton 'appManager'
    windowController     = KD.singleton 'windowController'
    display              = KD.singleton 'display'

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane

    appManager.on 'AppIsBeingShown', (controller)=>
      @setBodyClass KD.utils.slugify controller.getOption 'name'

    display.on 'ContentDisplayWantsToBeShown', do =>
      type = null
      (view)=>
        if type = view.getOption 'type'
          @setBodyClass type

    windowController.on 'ScrollHappened', do ->
      threshold     = 50
      lastScroll    = 0
      currentHeight = 0

      _.throttle (event)->
        el = document.body
        {scrollHeight, scrollTop} = el

        return  if scrollHeight <= window.innerHeight or scrollTop <= 0

        current = scrollTop + window.innerHeight
        if current > scrollHeight - threshold
          return if lastScroll > 0
          appManager.getFrontApp()?.emit "LazyLoadThresholdReached"
          lastScroll    = current
          currentHeight = scrollHeight
        else if current < lastScroll then lastScroll = 0

        if scrollHeight isnt currentHeight then lastScroll = 0
      , 200

  setBodyClass: do ->

    previousClass = null

    (name)->

      {body} = document
      KDView.setElementClass body, 'remove', previousClass  if previousClass
      KDView.setElementClass body, 'add', name
      previousClass = name

  loadView:(mainView)->

    mainView.ready =>

      {body} = document
      if KD.checkFlag 'super-admin'
      then KDView.setElementClass body, 'add', 'super'
      else KDView.setElementClass body, 'remove', 'super'

  mainTabPaneChanged:(mainView, pane)->

    appManager      = KD.getSingleton 'appManager'
    app             = appManager.getFrontApp()
    {mainTabView}   = mainView
    {navController} = KD.singleton 'dock'

    # KD.singleton('display').emit "ContentDisplaysShouldBeHidden"
    # temp fix
    # until fixing the original issue w/ the dnd this should be kept here
    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()

    {title} = app?.getOption('navItem')

    if title
    then navController.selectItemByName title
    else navController.deselectAllItems()


  setViewState: (options = {}) ->

    {behavior, name} = options

    html     = document.documentElement
    mainView = @getView()

    fullSizeApps = ['Login']
    appsWithDock = [
      'Activity', 'Members', 'content-display', 'Apps', 'Dashboard', 'Account'
      'Environments', 'Bugs'
    ]

    if (isApp = behavior is 'application') or (name in fullSizeApps)
    then KDView.setElementClass html, 'add', 'app'
    else KDView.setElementClass html, 'remove', 'app'

    if isApp or name in appsWithDock
    then @getView().showDock()
    else @getView().hideDock()
