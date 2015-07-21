kd                 = require 'kd'
JView              = require 'app/jview'
remote             = require('app/remote').getInstance()
KDButtonView       = kd.ButtonView
KDListItemView     = kd.ListItemView
integrationHelpers = require 'app/helpers/integration'


module.exports = class AdminIntegrationItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-view'

    { @integrationType, @name } = data
    @createButton data

    super options, data


  createButton: (data) ->

    @button    = new KDButtonView
      cssClass : 'solid compact green add'
      title    : if @integrationType is 'new' then 'Add' else 'Configure'
      callback : =>
        kd.singletons.router.handleRoute "/Admin/Integrations/Add/#{@name}"


  pistachio: ->

    { title, summary, iconPath } = @getData()

    return """
      <img src="#{iconPath}" />
      {p{ #(title)}}
      {span{ #(summary)}}
      {{> @button}}
    """
