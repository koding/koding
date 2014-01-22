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
    view = @getView()
    view.ready => view.handleQuery query
