AdminIntegrationsListView          = require './adminintegrationslistview'
AdminConfiguredIntegrationItemView = require './adminconfiguredintegrationitemview'


module.exports = class AdminConfiguredIntegrationsListView extends AdminIntegrationsListView

  constructor: (options = {}, data) ->

    options.listItemClass     = AdminConfiguredIntegrationItemView
    options.fetcherMethodName = 'listChannelIntegrations'

    super options, data


  registerListItem: (item) ->

    super

    item.on 'IntegrationCustomizeRequested', (integrationData) =>
      @showIntegrationDetails integrationData
