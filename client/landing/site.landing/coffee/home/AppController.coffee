HomeView = require './AppView'

module.exports = class HomeAppController extends KDViewController

  KD.registerAppClass this,
    name  : 'Home'
    route : '/Home'


  constructor: (options = {}, data) ->

    options.view = new HomeView
      cssClass   : 'content-page home'
    options.appInfo =
      name       : "Home"

    super options, data


  handleQuery: ({ query }) ->

    { provider } = query
    if provider
      KD.singletons.oauthController.authCompleted null, provider
