kd                          = require 'kd'
JView                       = require 'app/jview'
integrationHelpers          = require 'app/helpers/integration'
AdminIntegrationSetupView   = require './adminintegrationsetupview'
AdminIntegrationDetailsView = require './adminintegrationdetailsview'


module.exports = class AdminIntegrationParentView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @setClass 'integrations'

    @createFakeTabs()


  handleIdentifier: (identifier, action) ->

    @identifier = identifier

    @mainView?.destroy()
    @createLoadingView()

    if action is 'Add' then @handleAdd() else @handleConfigure()


  handleAdd: ->

    @addTab.setClass 'active'
    @configureTab.unsetClass 'active'

    integrationHelpers.find @identifier, (err, data) =>
      return @handleError err  if err

      @addSubView @mainView = new AdminIntegrationSetupView {}, data
      @mainView.on 'NewIntegrationAdded', =>
        integrationsTab = @getDelegate().getPaneByName 'Integrations'
        integrationsTab.mainView.configuredListView.refresh()

      @loader?.destroy()


  handleConfigure: ->

    @addTab.unsetClass 'active'
    @configureTab.setClass 'active'

    options = { id: @identifier }

    integrationHelpers.fetchConfigureData options, (err, data) =>
      return @handleError err  if err

      @loader?.destroy()
      @addSubView @mainView = new AdminIntegrationDetailsView {}, data

      @mainView.on 'IntegrationRemoved', =>
        adminTabView           = @getDelegate()
        { configuredListView } = adminTabView.getPaneByName('Integrations').mainView

        configuredListView.refresh()


  handleError: (err) ->

    kd.warn err

    partial = 'There was an error please try again.'

    if err.message is 'Not found'
      partial = 'There is no integration related with this identifier.'

    @loader?.destroy()
    @addSubView @mainView = new kd.CustomHTMLView { partial, cssClass: 'error-view' }


  createLoadingView: ->

    @addSubView @loader = new kd.LoaderView
      size       : width : 26
      cssClass   : 'action-container'
      showLoader : yes


  createFakeTabs: ->

    { router } = kd.singletons

    @addSubView wrapper = new kd.CustomHTMLView
      cssClass : 'kdtabhandlecontainer'
      partial  : '<div class="kdview kdtabhandle-tabs clearfix"></div>'

    wrapper.addSubView @addTab = new kd.CustomHTMLView
      cssClass : 'kdtabhandle all-services'
      partial  : '<b>All Services</b>'
      click    : -> router.handleRoute '/Admin/Integrations/Add'

    wrapper.addSubView @configureTab = new kd.CustomHTMLView
      cssClass : 'kdtabhandle'
      partial  : '<b>Configured Integrations</b>'
      click    : -> router.handleRoute '/Admin/Integrations/Configure'
