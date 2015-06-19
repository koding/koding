kd                                 = require 'kd'
AdminIntegrationsListView          = require './adminintegrationslistview'
AdminConfiguredIntegrationItemView = require './adminconfiguredintegrationitemview'


module.exports = class AdminConfiguredIntegrationsListView extends AdminIntegrationsListView

  constructor: (options = {}, data) ->

    options.listItemClass = AdminConfiguredIntegrationItemView

    super options, data


  fetchIntegrations: ->

    kd.singletons.socialapi.integrations.fetchChannelIntegrations (err, data) =>

      return @handleNoItem err  if err

      @listItems data
