kd = require 'kd'
AppController = require 'app/appcontroller'
MigrateFromSoloAppView = require './migratefromsoloappview'

do require './routehandler'

module.exports = class MigrateFromSoloAppController extends AppController

  @options =
    name: 'Migratefromsolo'
    background: yes

  constructor: (options = {}, data) ->

    options.view ?= new MigrateFromSoloAppView

    super options, data
