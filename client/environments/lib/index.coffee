kd = require 'kd'
EnvironmentsMainScene = require './views/environmentsmainscene'
AppController = require 'app/appcontroller'
require('./routehandler')()


module.exports = class EnvironmentsAppController extends AppController

  @options =
    name         : 'Environments'
    behavior     : 'application'

  constructor:(options = {}, data)->

    options.view    = new EnvironmentsMainScene
      cssClass      : 'environments split-layout'
    options.appInfo =
      name          : 'Environments'

    super options, data
