module.exports = class MainViewController extends KDViewController

  logViewByElement = (el) ->

    for id, view of KD.instances when view.getElement?
      if el is view.getElement()
        log view
        break

    logViewByElement el.parentNode  unless el.parentNode is document.body


  constructor:->

    super

    mainView = @getView()

    {repeat, killRepeat} = KD.utils

    {windowController, mainController, router} = KD.singletons

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane
      @setBodyClass pane.name.toLowerCase()

    if KD.config?.environment isnt 'production'
      window.addEventListener 'click', (event) =>
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes


  setBodyClass: do ->

    previousClass = null

    (name)->

      {body} = document
      KDView.setElementClass body, 'remove', previousClass  if previousClass
      KDView.setElementClass body, 'add', name
      previousClass = name


  mainTabPaneChanged:(mainView, pane)->