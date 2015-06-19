kd                                 = require 'kd'
AdminIntegrationsListView          = require './adminintegrationslistview'
AdminConfiguredIntegrationItemView = require './adminconfiguredintegrationitemview'


module.exports = class AdminConfiguredIntegrationsListView extends AdminIntegrationsListView

  constructor: (options = {}, data) ->

    options.listItemClass     = AdminConfiguredIntegrationItemView
    options.fetcherMethodName = 'fetchChannelIntegrations'

    super options, data
