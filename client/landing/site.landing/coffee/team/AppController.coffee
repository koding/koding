TeamView = require './AppView'

module.exports = class TeamAppController extends KDViewController

  KD.registerAppClass this,
    name : 'Team'

  stepMap =
    alloweddomain : 'allowedDomain'

  constructor: (options = {}, data) ->

    options.view = new TeamView cssClass : 'Team content-page'

    super options, data


  jumpTo: (step, query) ->

    return  unless step

    appView = @getView()
    method  = "create#{(stepMap[step] or step).capitalize()}Tab"

    appView[method]? query
