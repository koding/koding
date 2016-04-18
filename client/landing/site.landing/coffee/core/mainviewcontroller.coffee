kd = require 'kd'
module.exports = class MainViewController extends kd.ViewController

  logViewByElement = (el) ->

    for id, view of kd.instances when view.getElement?
      if el is view.getElement()
        console.log view
        break

    logViewByElement el.parentNode  unless el.parentNode is document.body


  constructor: ->

    super

    mainView = @getView()

    { repeat, killRepeat } = kd.utils

    { windowController, mainController, router } = kd.singletons

    mainView.on 'MainTabPaneShown', (pane) =>
      @mainTabPaneChanged mainView, pane
      @setBodyClass pane.name.toLowerCase()

    if kd.config?.environment isnt 'production'
      window.addEventListener 'click', (event) ->
        if event.metaKey and event.altKey
          logViewByElement event.target
      , yes


  setBodyClass: do ->

    previousClass = 'home'


    (name) ->

      { body } = document
      kd.View.setElementClass body, 'remove', previousClass  if previousClass
      kd.View.setElementClass body, 'add', name
      previousClass = name

  mainTabPaneChanged: (mainView, pane) ->
