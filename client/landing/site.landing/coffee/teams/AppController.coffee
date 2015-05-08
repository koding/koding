TeamsView = require './AppView'

module.exports = class TeamsAppController extends KDViewController

  KD.registerAppClass this, name : 'Teams'

  constructor: (options = {}, data) ->

    options.view = new TeamsView
      cssClass   : 'content-page teams'

    super options, data
