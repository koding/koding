kd                       = require 'kd'
remote                   = require('app/remote').getInstance()
globals                  = require 'globals'
showError                = require 'app/util/showError'
KDButtonView             = kd.ButtonView
KDTimeAgoView            = kd.TimeAgoView
KDCustomHTMLView         = kd.CustomHTMLView
AdminIntegrationItemView = require './adminintegrationitemview'


module.exports = class AdminConfiguredIntegrationItemView extends AdminIntegrationItemView


  createButton: (data) ->

    @button    = new KDButtonView
      cssClass : 'solid compact outline configure'
      title    : "#{data.channelIntegrations.length} Configured"
      loader   : color: '#4a4e52', diameter: 16
      callback : =>
        if @listView
          @listView.toggleClass 'hidden'
          @toggleClass 'list-visible'
          @button.hideLoader()
        else
          @button.showLoader()
          @createList()


  createList: ->

    batch        = []
    jAccounts    = {}
    integrations = @getData().channelIntegrations

    for item in integrations
      batch.push constructorName: 'JAccount', id: item.accountOldId

    remote.cacheable batch, (err, accounts) =>
      if err
        @button.hideLoader()
        return showError err

      for account in accounts
        jAccounts[account.getId()] = account

      @listView = new KDCustomHTMLView cssClass: 'configured-list'

      integrations.forEach (item) =>
        @createSubItem item, jAccounts[item.accountOldId]
        @addSubView @listView

      @button.hideLoader()
      @toggleClass 'list-visible'


  createSubItem: (data, account) ->

    @listView.addSubView subview = new KDCustomHTMLView
      cssClass : 'integration'
      partial  : """
        <p>posts to ##{data.channel.name} channel</p>
        <p class="by">added by #{account.profile.nickname}</p>
      """

    subview.addSubView new KDTimeAgoView {}, data.channelIntegration.createdAt
    subview.addSubView new KDCustomHTMLView
      cssClass : 'edit'
      partial  : 'Customize <span></span>'
      click    : => @handleCustomize data


  handleCustomize: (integrationData) ->

    { integration } = @getData()
    { channelIntegration } = integrationData

    @fetchChannels (err, channels) =>
      return showError err  if err

      data              =
        channels        : channels
        id              : channelIntegration.id
        name            : integration.name
        title           : integration.title
        token           : channelIntegration.token
        summary         : integration.summary
        settings        : channelIntegration.settings
        createdAt       : channelIntegration.createdAt
        iconPath        : integration.iconPath
        updatedAt       : channelIntegration.updatedAt
        description     : integration.description
        instructions    : integration.instructions
        typeConstant    : integration.typeConstant
        integrationId   : channelIntegration.integrationId
        selectedChannel : channelIntegration.channelId
        webhookUrl      : "#{globals.config.integration.url}/#{integration.name}/#{channelIntegration.token}"

      @emit 'IntegrationCustomizeRequested', data


  pistachio: ->
    data = @getData()
    { title, summary, iconPath } = @getData().integration

    return """
      <img src="#{iconPath}" />
      <p>#{title}</p>
      <span>#{summary}</span>
      {{> @button}}
    """
