TeamsView = require './AppView'

module.exports = class TeamsAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Teams'
    route : '/Teams'


  constructor: (options = {}, data) ->

    options.view = new TeamsView
      cssClass   : 'content-page teams'

    super options, data

    console.log 'hellllllllllllllllllloooooooooooooooooooooo'

  jumpTo: ->

    console.log 'jumpTo'
