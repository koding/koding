kd                       = require 'kd'
KDButtonView             = kd.ButtonView
AdminIntegrationItemView = require './adminintegrationitemview'


module.exports = class AdminConfiguredIntegrationItemView extends AdminIntegrationItemView


  createButton: (data) ->

    @button = new KDButtonView
      cssClass : 'outline compact green configure'
      title    : "#{data.channelIntegrations.length} Configured"
      callback : ->


  pistachio: ->
    data = @getData()
    { title, summary, iconPath } = @getData().integration

    return """
      <img src="#{iconPath}" />
      <p>#{title}</p>
      <span>#{summary}</span>
      {{> @button}}
    """
