globals = require 'globals'
checkFlag = require './util/checkFlag'
kd = require 'kd'
KDView = kd.View
KDViewController = kd.ViewController
module.exports = class MainViewController extends KDViewController

  logViewByElement = (el) ->

    for __, view of kd.instances when view.getElement?
      if el is view.getElement()
        kd.log view
        break

    logViewByElement el.parentNode  unless el.parentNode is global.document.body


  constructor: ->

    super

    mainView             = @getView()
    appManager           = kd.singleton 'appManager'

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane

    appManager.on 'AppIsBeingShown', (controller) =>
      { customName, name } = controller.getOptions()
      @setBodyClass kd.utils.slugify customName ? name

    if globals.config?.environment isnt 'production'
      global.addEventListener 'click', (event) ->
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes


  loadView: (mainView) ->

    mainView.ready ->

      { body } = global.document
      if checkFlag 'super-admin'
      then KDView.setElementClass body, 'add', 'super'
      else KDView.setElementClass body, 'remove', 'super'


  setBodyClass: do ->

    previousClass = null

    (name) ->

      { body } = global.document
      KDView.setElementClass body, 'remove', previousClass  if previousClass
      KDView.setElementClass body, 'add', name
      previousClass = name


  mainTabPaneChanged: (mainView, pane) ->

    appManager      = kd.getSingleton 'appManager'
    { mainTabView } = mainView

    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()


  setViewState: (options = {}) ->

    { behavior, name } = options

    html     = global.document.documentElement
    mainView = @getView()

    fullSizeApps    = [ 'content-display' ]
    appsWithSidebar = [ 'content-display', 'Dashboard', 'Stackeditor' ]

    if (isApp = behavior is 'application') or (name in fullSizeApps)
    then KDView.setElementClass html, 'add', 'app'
    else KDView.setElementClass html, 'remove', 'app'

    if isApp or name in appsWithSidebar
    then mainView.setClass 'with-sidebar'
    else mainView.unsetClass 'with-sidebar'
