class TeamworkAppController extends AppController

  KD.registerAppClass this,
    name            : "Teamwork"
    route           : "/:name?/Teamwork"

  constructor: (options = {}, data) ->

    options.view    = new TeamworkAppView

    options.appInfo =
      type          : "application"
      name          : "Teamwork"

    super options, data

  handleQuery: (query) ->
    @getView().ready => @getView().handleQuery query
