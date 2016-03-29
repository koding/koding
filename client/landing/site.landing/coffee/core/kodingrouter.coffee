kd = require 'kd'
module.exports = class KodingRouter extends kd.Router

  constructor: (@defaultRoute) ->

    @breadcrumb = []
    @defaultRoute or= location.pathname + location.search
    @openRoutes     = {}
    @openRoutesById = {}
    @appControllers = {}

    super()

    @on 'AlreadyHere', -> console.log "You're already here!"


  listen: ->

    @startListening()

    return if @userRoute

    kd.utils.defer =>
      @handleRoute @defaultRoute,
        shouldPushState : yes
        replaceState    : yes


  handleRoute: (route, options = {}) ->

    @breadcrumb.push route

    super route, options


  openSection: (name, group, query, callback) ->

    { mainView }    = kd.singletons
    { mainTabView } = mainView

    if pane = mainTabView.getPaneByName name
      mainTabView.showPane pane
      callback? @appControllers[name]
    else
      mainView.ready => @showApp name, callback


  showApp: (name, callback) ->

    { mainView : { mainTabView } } = kd.singletons

    @requireApp name, (app, pane) ->
      mainTabView.showPane pane
      callback? app, pane


  requireApp: (name, callback) ->

    { mainView : { mainTabView } } = kd.singletons

    if app = @appControllers[name]
      pane = mainTabView.getPaneByName name
      return callback? app, pane

    AppClass              = kd.getAppClass name
    app                   = new AppClass
    view                  = app.getView()
    pane                  = mainTabView.createTabPane { name, shouldShow : no }, view
    @appControllers[name] = app

    callback? app, pane


  handleNotFound: (route) -> @handleRoute '/', { replaceState: yes }


  getDefaultRoute: -> '/'


  setPageTitle: (title = 'Koding') -> document.title = Encoder.htmlDecode title


  clear: (route, replaceState = yes) ->

    route or= '/'

    super route, replaceState
