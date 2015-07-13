kd                       = require 'kd'
remote                   = require('app/remote').getInstance()
globals                  = require 'globals'
showError                = require 'app/util/showError'
KDButtonView             = kd.ButtonView
KDTimeAgoView            = kd.TimeAgoView
KDCustomHTMLView         = kd.CustomHTMLView
AdminIntegrationItemView = require './adminintegrationitemview'
integrationHelpers       = require 'app/helpers/integration'


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

    integrationHelpers.fetchChannels (err, channels) =>
      return showError err  if err

      integrationHelpers.fetch {id: channelIntegration.id}, (err, response) =>

        return showError err  if err

        { channelIntegration } = response

        data              =
          channels        : channels
          id              : channelIntegration.id
          integration     : integration
          token           : channelIntegration.token
          createdAt       : channelIntegration.createdAt
          updatedAt       : channelIntegration.updatedAt
          description     : channelIntegration.description or integration.summary
          integrationId   : channelIntegration.integrationId
          selectedChannel : channelIntegration.channelId
          webhookUrl      : "#{globals.config.integration.url}/#{integration.name}/#{channelIntegration.token}"
          integrationType : 'configured'
          isDisabled      : channelIntegration.isDisabled
          selectedEvents  : []


        if channelIntegration.settings
          data.selectedEvents = try JSON.parse channelIntegration.settings.events
          catch e then []

        if integration.settings?.events
          events = try JSON.parse integration.settings.events
          catch e then null
          data.settings = { events }

        unless integration.name is 'github'
          return @emit 'IntegrationCustomizeRequested', data

        integrationHelpers.fetchGithubRepos (err, repositories) =>

          return showError err  if err
          data.repositories = repositories

          @emit 'IntegrationCustomizeRequested', data



  pistachio: ->

    { integration } = @getData()

    return """
      <img src="#{integration.iconPath}" />
      {p{ #(integration.title)}}
      {span{ #(integration.summary)}}
      {{> @button}}
    """
