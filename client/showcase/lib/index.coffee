kd = require 'kd'
AppController = require 'app/appcontroller'
ShowcaseAppView = require './appview'

require('./routehandler')()

module.exports = class ShowcaseAppController extends AppController

  @options = { name: 'Showcase' }

  constructor: (options, data) ->

    options.appInfo = { title: 'Showcase' }
    options.view = new ShowcaseAppView

    super options, data
