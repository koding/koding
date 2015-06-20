kd                       = require 'kd'
KDButtonView             = kd.ButtonView
KDTimeAgoView            = kd.TimeAgoView
KDCustomHTMLView         = kd.CustomHTMLView
AdminIntegrationItemView = require './adminintegrationitemview'


module.exports = class AdminConfiguredIntegrationItemView extends AdminIntegrationItemView


  createButton: (data) ->

    @button = new KDButtonView
      cssClass : 'solid compact outline configure'
      title    : "#{data.channelIntegrations.length} Configured"
      callback : =>
        if @listView then @listView.toggleClass 'hidden' else @createList()


  createList: ->

    @listView = new KDCustomHTMLView cssClass: 'configured-list'

    @getData().channelIntegrations.forEach (item) =>
      @listView.addSubView subview = new kd.CustomHTMLView
        cssClass : 'integration'
        partial  : """
          <p>posts to ##{item.channelId} channel</p>
          <p class="by">added by #{item.creatorId}</p>
        """

      subview.addSubView new KDTimeAgoView {}, item.createdAt
      subview.addSubView new KDCustomHTMLView
        cssClass : 'edit'
        partial  : 'Customize <span></span>'
        click    : => kd.log '..........'

    @addSubView @listView


  pistachio: ->
    data = @getData()
    { title, summary, iconPath } = @getData().integration

    return """
      <img src="#{iconPath}" />
      <p>#{title}</p>
      <span>#{summary}</span>
      {{> @button}}
    """
