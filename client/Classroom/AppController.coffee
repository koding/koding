class ClassroomAppController extends AppController

  KD.registerAppClass this,
    name            : "Classroom"
    route           : "/:name?/Develop/Classroom"

  constructor: (options = {}, data) ->

    options.view    = new ClassroomAppView

    options.appInfo =
      type          : "application"
      name          : "Classroom"

    super options, data

  handleQuery: (query) ->
    @getView().ready => @getView().handleQuery query
