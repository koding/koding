checkFlag = require '../../util/checkFlag'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView

LinkView = require './linkview'

module.exports = class ProfileLinkView extends LinkView



  constructor: (options = {}, data) ->
    options.noTooltip ?= yes

    if @avatarPreview then options.tooltip or=
      view             : unless options.noTooltip then @avatarPreview else null
      cssClass         : 'avatar-tooltip'
      animate          : yes
      placement        : 'top'#['top','bottom','right','left'][Math.floor(Math.random()*4)]
      direction        : 'left'#['left','right','center','top','bottom'][Math.floor(Math.random()*5)]

    super options, data
    if @avatarPreview?
      @on 'TooltipReady', =>
        kd.utils.defer =>
          @tooltip?.getView()?.updateData @getData() if @getData()?.profile.nickname?

    @troll = new KDCustomHTMLView
      tagName   : 'span'

    @setClass 'profile'
    @updateHref()


  updateHref: ->
    { payload } = @getOptions()
    nickname = @getData().profile?.nickname

    href = if payload?.channelIntegrationId
      "/Admin/Integrations/Configure/#{payload.channelIntegrationId}"
    else
      '/#'

    @setAttribute 'href', href  if href


  render: (fields) ->
    @updateHref()

    # only admin can see troll users
    if checkFlag 'super-admin'
      trollField = if @getData().isExempt then ' (T)' else ''
      @troll.updatePartial trollField  if @troll

    super fields

  pistachio: ->
    { payload } = @getOptions()
    { profile } = @getData()
    kd.View::pistachio.call this,
      if payload?.integrationTitle
      then "#{payload.integrationTitle}"
      else if profile.firstName is '' and profile.lastName is ''
      then '{{#(profile.nickname)}} {{> @troll}}'
      else "{{#(profile.firstName)+' '+#(profile.lastName)}} {{> @troll}}"
