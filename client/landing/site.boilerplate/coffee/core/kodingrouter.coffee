module.exports = class KodingRouter extends KDRouter

  constructor: (@defaultRoute) ->

    @breadcrumb = []
    @defaultRoute or= location.pathname + location.search
    @openRoutes     = {}
    @openRoutesById = {}
    @appControllers = {}

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


  openSection: (name, group, query, callback) ->

    {mainView}    = KD.singletons
    {mainTabView} = mainView

    if pane = mainTabView.getPaneByName name
      mainTabView.showPane pane
      callback? @appControllers[name]
    else
      mainView.ready => @showApp name, callback


  showApp: (name, callback)->

    {mainView : {mainTabView}} = KD.singletons

    @requireApp name, (app, pane) =>
      mainTabView.showPane pane
      callback? app, pane


  requireApp: (name, callback)->

    {mainView : {mainTabView}} = KD.singletons
    AppClass              = KD.getAppClass name
    app                   = new AppClass
    view                  = app.getView()
    pane                  = mainTabView.createTabPane {name, shouldShow : no}, view
    @appControllers[name] = app

    callback? app, pane


  handleNotFound: (route) -> @handleRoute '/', replaceState: yes


  getDefaultRoute: -> '/'


  setPageTitle: (title = 'Koding') -> document.title = Encoder.htmlDecode title


  clear: (route, replaceState = yes) ->

    route or= '/'

    super route, replaceState
