TeamView = require './AppView'

module.exports = class TeamAppController extends KDViewController

  KD.registerAppClass this,
    name       : 'Team'
    background : yes

  constructor: (options = {}, data) ->

    options.view = new TeamView cssClass : 'Team content-page'

    super options, data