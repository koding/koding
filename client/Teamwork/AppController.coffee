class TeamworkAppController extends AppController

  KD.registerAppClass this,
    name            : "Teamwork"
    route           : "/:name?/Teamwork"
    behavior        : "application"
    enforceLogin    : yes

  constructor: (options = {}, data) ->

    options.view    = new TeamworkAppView

    options.appInfo =
      type          : "application"
      name          : "Teamwork"

    super options, data


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
