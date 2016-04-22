kd                  = require 'kd'
AppController       = require 'app/appcontroller'
DefineStackView     = require 'stacks/views/stacks/definestackview'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'

  constructor: (options = {}, data) ->

    options.view = view = new DefineStackView { skipFullscreen : yes }, { showHelpContent : yes }

    super options, data

    view.on 'Cancel', -> kd.singletons.router.back()
