kd                  = require 'kd'
AppController       = require 'app/appcontroller'
DefineStackView     = require 'stacks/views/stacks/definestackview'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'

  constructor: (options = {}, data) ->

    options.view = new DefineStackView {}, { showHelpContent : yes }

    super options, data
