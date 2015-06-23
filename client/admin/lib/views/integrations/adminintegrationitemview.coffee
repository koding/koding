kd             = require 'kd'
JView          = require 'app/jview'
remote         = require('app/remote').getInstance()
KDButtonView   = kd.ButtonView
KDListItemView = kd.ListItemView


module.exports = class AdminIntegrationItemView extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'integration-view'

    { @integrationType } = data
    @createButton data

    super options, data


  createButton: (data) ->

    @button    = new KDButtonView
      cssClass : 'solid compact green add'
      title    : if @integrationType is 'new' then 'Add' else 'Configure'
      loader   : yes
      callback : =>
        if      @integrationType is 'new' then @fetchIntegrationChannels()
        else if @integrationType is 'configured'
          @fetchIntegrationDetails()


  fetchIntegrationChannels: ->

    data = @getData()

    @fetchChannels (err, channels) =>
      return  if err

      data.channels = channels

      @button.hideLoader()
      @emit 'IntegrationGroupsFetched', data


  fetchChannels: (callback) ->

    kd.singletons.socialapi.account.fetchChannels (err, channels) =>
      return callback err  if err

      decoratedChannels = []

      for channel in channels
        { id, typeConstant, name, purpose, participantsPreview } = channel

        # TODO after refactoring the private channels, we also need
        # to add them here
        if typeConstant is 'topic' or typeConstant is 'group'
          decoratedChannels.push { name:"##{name}", id }

      callback null, decoratedChannels

  pistachio: ->

    { title, summary, iconPath } = @getData()

    return """
      <img src="#{iconPath}" />
      {p{ #(title)}}
      {span{ #(summary)}}
      {{> @button}}
    """
