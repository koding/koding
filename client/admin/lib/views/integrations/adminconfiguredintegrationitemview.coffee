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

    { id, createdAt, isDisabled } = data.channelIntegration

    disabledMarkup = ''

    if isDisabled
      disabledMarkup = '<span class="tag">DISABLED</span>'

    @listView.addSubView subview = new KDCustomHTMLView
      cssClass : 'integration'
      partial  : """
        <p>posts to ##{data.channel.name} channel#{disabledMarkup}</p>
        <p class="by">added by #{account.profile.nickname}</p>
      """

    subview.addSubView new KDTimeAgoView {}, createdAt
    subview.addSubView new KDCustomHTMLView
      cssClass : 'edit'
      partial  : 'Customize <span></span>'
      click    : ->
        kd.singletons.router.handleRoute "/Admin/Integrations/Configure/#{id}"


  pistachio: ->

    { integration } = @getData()

    return """
      <img src="#{integration.iconPath}" />
      {p{ #(integration.title)}}
      {span{ #(integration.summary)}}
      {{> @button}}
    """
