class MainViewController extends KDViewController

  logViewByElement = (el) ->

    for id, view of KD.instances when view.getElement?
      if el is view.getElement()
        log view
        break

    logViewByElement el.parentNode  unless el.parentNode is document.body


  constructor:->

    super

    {repeat, killRepeat} = KD.utils
    mainView             = @getView()
    appManager           = KD.singleton 'appManager'
    windowController     = KD.singleton 'windowController'
    display              = KD.singleton 'display'
    mainController       = KD.singleton 'mainController'

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane

    appManager.on 'AppIsBeingShown', (controller) =>
      @setBodyClass KD.utils.slugify controller.getOption 'name'


    display?.on 'ContentDisplayWantsToBeShown', do =>
      type = null
      (view) => @setBodyClass type  if type = view.getOption 'type'

    windowController.on 'ScrollHappened', @bound 'handleScroll'

    if KD.config?.environment isnt 'production'
      window.addEventListener 'click', (event) =>
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes


  loadView:(mainView)->

    mainView.ready =>

      {body} = document
      if KD.checkFlag 'super-admin'
      then KDView.setElementClass body, 'add', 'super'
      else KDView.setElementClass body, 'remove', 'super'


  handleScroll: do ->

    threshold     = 50
    lastPos       = 0

    (event) ->

      {scrollHeight, scrollTop} = document.body
      {innerHeight}             = window

      # return when it pulls the page on top
      return lastPos = innerHeight  if scrollTop <= 0

      # return when it pulls the page at the bottom
      return  if scrollHeight - scrollTop < innerHeight

      currentPos = scrollTop + innerHeight
      direction  = if currentPos > lastPos then 'down' else 'up'

      appManager = KD.singleton 'appManager'
      frontApp   = appManager.getFrontApp() or this

      switch direction
        when 'up'
          if scrollTop < threshold
            frontApp?.emit 'TopLazyLoadThresholdReached'
        when 'down'
          if currentPos > scrollHeight - threshold
            frontApp?.emit 'LazyLoadThresholdReached'

      lastPos = currentPos


  setBodyClass: do ->

    previousClass = null

    (name)->

      {body} = document
      KDView.setElementClass body, 'remove', previousClass  if previousClass
      KDView.setElementClass body, 'add', name
      previousClass = name


  mainTabPaneChanged:(mainView, pane)->

    appManager      = KD.getSingleton 'appManager'
    app             = appManager.getFrontApp()
    {mainTabView}   = mainView
    warn 'set active nav item by route change, not by maintabpane change'

    # KD.singleton('display').emit "ContentDisplaysShouldBeHidden"
    # temp fix
    # until fixing the original issue w/ the dnd this should be kept here
    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()


  setViewState: (options = {}) ->

    {behavior, name} = options

    html     = document.documentElement
    mainView = @getView()

    fullSizeApps = ['Login', 'Pricing']
    appsWithSidebar = [
      'Activity', 'Members', 'content-display', 'Apps', 'Dashboard', 'Account'
      'Environments', 'Bugs'
    ]

    if (isApp = behavior is 'application') or (name in fullSizeApps)
    then KDView.setElementClass html, 'add', 'app'
    else KDView.setElementClass html, 'remove', 'app'

    if isApp or name in appsWithSidebar
    then mainView.setClass 'with-sidebar'
    else mainView.unsetClass 'with-sidebar'
