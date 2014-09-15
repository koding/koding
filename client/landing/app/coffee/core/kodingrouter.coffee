Home  = require './../about/AppController'
About = require './../home/AppController'
Login = require './../login/AppController'

module.exports = class KodingRouter extends KDRouter

  constructor: (@defaultRoute) ->

    @breadcrumb = []
    @defaultRoute or= location.pathname + location.search
    @openRoutes     = {}
    @openRoutesById = {}

    super()

    @on 'AlreadyHere', -> log "You're already here!"


  listen: ->

    super

    return if @userRoute

    KD.utils.defer =>
      @handleRoute @defaultRoute,
        shouldPushState : yes
        replaceState    : yes


  handleRoute: (route, options = {}) ->

    @breadcrumb.push route

    super route, options


  openSection: (name, group, query) ->

    {mainView}    = KD.singletons
    {mainTabView} = mainView

    if pane = mainTabView.getPaneByName name
      mainTabView.showPane pane
    else
      mainView.ready =>
        AppClass = KD.getAppClass name
        app      = new AppClass
        view     = app.getView()
        mainTabView.createTabPane {name}, view


  getDefaultRoute: -> '/'


  setPageTitle: (title = 'Koding') -> document.title = Encoder.htmlDecode title


  clear: (route, replaceState = yes) ->

    route or= '/'

    super route, replaceState
