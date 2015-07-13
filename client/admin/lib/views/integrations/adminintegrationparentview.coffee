JView                     = require 'app/jview'
integrationHelpers        = require 'app/helpers/integration'
AdminIntegrationSetupView = require './adminintegrationsetupview'


module.exports = class AdminIntegrationParentView extends JView


  handleIdentifier: (identifier) ->

    @mainView?.destroy()

    integrationHelpers.find identifier, (err, data) =>
      @addSubView @mainView = new AdminIntegrationSetupView {}, data
