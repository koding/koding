class TeamworkAppController extends AppController

  KD.registerAppClass this,
    name         : "Teamwork"
    route        : "/:name?/Teamwork"
    behavior     : "application"
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn() or KD.isLoggedInOnLoad
      failure    : (options, cb)->
        KD.singletons.appManager.open 'Teamwork', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor: (options = {}, data) ->

    options.view    = new TeamworkAppView

    options.appInfo =
      type          : "application"
      name          : "Teamwork"

    super options, data

    KD.singletons.appManager.on 'AppIsBeingShown', (app)=>
      if app.getId() is @getId()
        KD.utils.defer -> $(window).trigger 'resize'


  handleQuery: (query) ->

    search = location.search
    if /guest-/.test search
      search = ""

    path = location.pathname + search
    mainController = KD.getSingleton("mainController")
    mainController.once "accountChanged.to.loggedIn", =>
      location.replace path

    view = @getView()
    view.ready => view.handleQuery query
