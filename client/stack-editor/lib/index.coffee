kd                  = require 'kd'
AppController       = require 'app/appcontroller'
DefineStackView     = require 'stacks/views/stacks/definestackview'
showError           = require 'app/util/showError'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'
    behavior   : 'application'


  openSection: (section, query) ->

    { computeController } = kd.singletons

    @mainView.destroySubViews()

    if section
      computeController.fetchStackTemplate section, (err, stackTemplate) =>
        return showError err  if err
        @createView stackTemplate
    else
      @createView()


  createView: (stackTemplate) ->

    options = { skipFullscreen : yes }
    data    = { stackTemplate, showHelpContent : yes }
    view    = new DefineStackView options, data
    view.on 'Cancel', -> kd.singletons.router.back()

    @mainView.addSubView view
