globals = require 'globals'
checkFlag = require './util/checkFlag'
kd = require 'kd'
KDView = kd.View
KDViewController = kd.ViewController
module.exports = class MainViewController extends KDViewController

  logViewByElement = (el) ->

    for id, view of kd.instances when view.getElement?
      if el is view.getElement()
        kd.log view
        break

    logViewByElement el.parentNode  unless el.parentNode is global.document.body


  constructor:->

    super

    mainView             = @getView()
    appManager           = kd.singleton 'appManager'
    windowController     = kd.singleton 'windowController'
    display              = kd.singleton 'display'
    mainController       = kd.singleton 'mainController'

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane

    appManager.on 'AppIsBeingShown', (controller) =>
      @setBodyClass kd.utils.slugify controller.getOption 'name'


    display?.on 'ContentDisplayWantsToBeShown', do =>
      type = null
      (view) => @setBodyClass type  if type = view.getOption 'type'

    if globals.config?.environment isnt 'production'
      global.addEventListener 'click', (event) =>
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes


  loadView:(mainView)->

    mainView.ready =>

      {body} = global.document
      if checkFlag 'super-admin'
      then KDView.setElementClass body, 'add', 'super'
      else KDView.setElementClass body, 'remove', 'super'


  setBodyClass: do ->

    previousClass = null

    (name)->

      {body} = global.document
      KDView.setElementClass body, 'remove', previousClass  if previousClass
      KDView.setElementClass body, 'add', name
      previousClass = name


  mainTabPaneChanged:(mainView, pane)->

    appManager      = kd.getSingleton 'appManager'
    app             = appManager.getFrontApp()
    {mainTabView}   = mainView

    # warn 'set active nav item by route change, not by maintabpane change'
    # kd.singleton('display').emit "ContentDisplaysShouldBeHidden"
    # temp fix
    # until fixing the original issue w/ the dnd this should be kept here
    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()


  setViewState: (options = {}) ->

    {behavior, name} = options

    html     = global.document.documentElement
    mainView = @getView()

    fullSizeApps    = [ 'Login', 'Activity', 'Teams', 'Welcome' ]
    appsWithSidebar = [
      'Activity', 'Members', 'content-display', 'Apps', 'Dashboard', 'Account'
      'Environments', 'Bugs', 'Welcome'
    ]

    if (isApp = behavior is 'application') or (name in fullSizeApps)
    then KDView.setElementClass html, 'add', 'app'
    else KDView.setElementClass html, 'remove', 'app'

    if isApp or name in appsWithSidebar
    then mainView.setClass 'with-sidebar'
    else mainView.unsetClass 'with-sidebar'


