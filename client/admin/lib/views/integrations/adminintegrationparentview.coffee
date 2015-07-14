JView                       = require 'app/jview'
integrationHelpers          = require 'app/helpers/integration'
AdminIntegrationSetupView   = require './adminintegrationsetupview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'


module.exports = class AdminIntegrationParentView extends JView


  handleIdentifier: (identifier, action) ->

    @identifier = identifier

    @mainView?.destroy()

    if action is 'add' then @handleAdd() else @handleConfigure()


  handleAdd: ->

    integrationHelpers.find @identifier, (err, data) =>
      @addSubView @mainView = new AdminIntegrationSetupView {}, data


  handleConfigure: ->

    @addSubView @mainView = new AdminIntegrationDetailsView {}, DUMMY_DATA
