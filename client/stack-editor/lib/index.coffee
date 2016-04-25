kd                  = require 'kd'
AppController       = require 'app/appcontroller'
DefineStackView     = require 'stacks/views/stacks/definestackview'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'


  openSection: (section, query) ->

    view = new DefineStackView { skipFullscreen : yes }, { showHelpContent : yes }
    view.on 'Cancel', -> kd.singletons.router.back()

    @mainView.destroySubViews()
    @mainView.addSubView view
