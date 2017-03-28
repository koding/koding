kd = require 'kd'
AppController = require 'app/appcontroller'
AnalyticsAppView = require './analyticsappview'

do require './routehandler'
require 'analytics/styl'

module.exports = class AnalyticsAppController extends AppController

  @options     = {
    name       : 'Analytics'
    behavior   : 'application'
  }

  constructor: (options = {}, data) ->

    data          ?= kd.singletons.groupsController.getCurrentGroup()
    options.view  ?= new AnalyticsAppView {}, data

    super options, data


  checkRoute: (route) -> /^\/(?:Analytics).*/.test route
