TeamLandingView = require './AppView'

module.exports = class TeamLandingAppController extends KDViewController

  KD.registerAppClass this,
    name       : 'TeamLanding'
    background : yes


  constructor: (options = {}, data) ->

    options.view = new TeamLandingView
      cssClass : 'TeamLanding content-page'

    super options, data
