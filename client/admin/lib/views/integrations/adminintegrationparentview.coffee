kd                          = require 'kd'
JView                       = require 'app/jview'
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
    @createLoadingView()

    if action is 'Add' then @handleAdd() else @handleConfigure()


  handleAdd: ->

    integrationHelpers.find @identifier, (err, data) =>
      return @handleError err  if err

      @addSubView @mainView = new AdminIntegrationSetupView {}, data
      @loader.destroy()


  handleConfigure: ->

    options = { id: @identifier }

    integrationHelpers.fetchConfigureData options, (err, data) =>
      return @handleError err  if err

      @addSubView @mainView = new AdminIntegrationDetailsView {}, data
      @loader.destroy()


  handleError: (err) ->

    kd.warn err

    partial = 'There was an error please try again.'

    if err.message is 'Not found'
      partial = 'There is no integration related with this identifier.'

    @addSubView @mainView = new kd.CustomHTMLView { partial, cssClass: 'error-view' }


  createLoadingView: ->

    @addSubView @loader = new kd.LoaderView
      size       : width : 26
      cssClass   : 'action-container'
      showLoader : yes
