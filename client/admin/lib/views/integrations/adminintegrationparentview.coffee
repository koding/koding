JView                       = require 'app/jview'
showError                   = require 'app/util/showError'
integrationHelpers          = require 'app/helpers/integration'
AdminIntegrationSetupView   = require './adminintegrationsetupview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'


module.exports = class AdminIntegrationParentView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @setClass 'integrations'


  handleIdentifier: (identifier, action) ->

    @identifier = identifier

    @mainView?.destroy()

    if action is 'Add' then @handleAdd() else @handleConfigure()


  handleAdd: ->

    integrationHelpers.find @identifier, (err, data) =>
      return @handleError err  if err

      @addSubView @mainView = new AdminIntegrationSetupView {}, data


  handleConfigure: ->

    @addSubView @mainView = new AdminIntegrationDetailsView {}, DUMMY_DATA

  handleError: (err) ->

    showError err
