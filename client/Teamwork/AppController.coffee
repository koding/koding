class TeamworkAppController extends AppController

  KD.registerAppClass this,
    name            : "Teamwork"
    route           : "/:name?/Teamwork"
    behavior        : "application"
    navItem         :
      title         : "Teamwork"
      path          : "/Teamwork"
      order         : 70

  constructor: (options = {}, data) ->

    options.view    = new TeamworkAppView

    options.appInfo =
      type          : "application"
      name          : "Teamwork"

    super options, data

  handleQuery: (query) ->
    @getView().ready => @getView().handleQuery query
