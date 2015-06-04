kd             = require 'kd'
JView          = require 'app/jview'
remote         = require('app/remote').getInstance()
KDButtonView   = kd.ButtonView
KDListItemView = kd.ListItemView


module.exports = class AdminIntegrationItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-view'

    super options, data

    { @integrationType } = @getData()

    @button    = new KDButtonView
      cssClass : 'solid compact green add'
      title    : if @integrationType is 'new' then 'Add' else 'Configure'
      loader   : yes
      callback : @bound 'fetchIntegrationChannels'


  fetchIntegrationChannels: ->

    remote.api.JAccount.some {}, {}, (err, data) =>
      @button.hideLoader()
      @emit 'IntegrationGroupsFetched', data


  pistachio: ->

    { name, desc, logo } = @getData()

    return """
      <img src="#{logo}" />
      {p{ #(name)}}
      {span{ #(desc)}}
      {{> @button}}
    """
