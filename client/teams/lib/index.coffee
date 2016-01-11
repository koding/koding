kd            = require 'kd'
AppController = require 'app/appcontroller'
TeamsAppView  = require './teamsappview'

module.exports = class TeamsAppController extends AppController

  @options =
    name  : 'Teams'
    route : '/Teams'

  constructor: (options = {}, data) ->

    options.appInfo = { title: 'Teams' }
    options.view = new TeamsAppView

    super options, data

    document.cookie = 'clientId=false'
    location.reload()
