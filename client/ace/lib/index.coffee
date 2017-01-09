isLoggedIn    = require 'app/util/isLoggedIn'
AppController = require 'app/appcontroller'
AceAppView    = require './aceappview'

require('./routehandler')()
require 'ace/styl'


module.exports = class AceAppController extends AppController

  @options = require './options'

  constructor: (options = {}, data) ->

    options.view = new AceAppView
    options.appInfo =
      name         : 'Ace'
      type         : 'application'
      cssClass     : 'ace'

    super options, data

    @on 'AppDidQuit', -> @getView().emit 'AceAppDidQuit'


  openFile: (file) ->

    @getView().openFile file
