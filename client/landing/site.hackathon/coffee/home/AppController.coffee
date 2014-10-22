HomeView = require './AppView'

module.exports = class HomeAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Home'
    route : '/Hackathon'


  constructor: (options = {}, data) ->

    options.view = new HomeView
      cssClass   : 'content-page home'

    super options, data
