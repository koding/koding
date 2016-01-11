kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDView = kd.View
remote = require('app/remote').getInstance()
showError = require 'app/util/showError'
whoami = require 'app/util/whoami'
ShowMoreDataModalView = require 'app/commonviews/showmoredatamodalview'
ProfileLinkView = require 'app/commonviews/linkviews/profilelinkview'


module.exports = class ActivityLikeSummaryView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry "like-summary hidden", options.cssClass

    super options, data

    data
      .on "LikeAdded",   @bound "updateActors"
      .on "LikeRemoved", @bound "updateActors"
      .on "LikeChanged", @bound "handleLikeChanged"


  showLikers: (event)->

    kd.utils.stopDOMEvent event

    {id} = @getData()

    kd.singleton("socialapi").message.listLikers {id}, (err, ids = []) ->

      return showError err  if err
      return  if ids.length is 0

      batch = ids.map do (constructorName = "JAccount") ->
        (id) -> {constructorName, id}

      remote.cacheable batch, (err, accounts) ->

        return showError err  if err
        new ShowMoreDataModalView
          title : 'Users who liked this'
        , accounts


  handleLikeChanged: (liked) ->

    {actorsPreview} = @getData().interactions.like

    if liked
      if whoami()._id not in actorsPreview
        actorsPreview.unshift whoami()._id
        @getData().interactions.like.actorsCount += 1
    else
      index = actorsPreview.indexOf whoami()._id
      if index > -1
        actorsPreview.splice index, 1
        @getData().interactions.like.actorsCount -= 1

    @updateActors()


  updateActors: ->

    @fetchPreviewAccounts (err, accounts) =>

      return showError err  if err

      @destroySubViews()
      @refresh accounts


  fetchPreviewAccounts: (callback) ->

    {actorsPreview} = @getData().interactions.like
    if actorsPreview?
      constructorName = "JAccount"
      origins = actorsPreview.map (id) -> {id, constructorName}

      remote.cacheable origins, callback
    else
      callback null, []


  refresh: (accounts = []) ->

    return @hide()  if accounts.length is 0

    {actorsCount, actorsPreview} = @getData().interactions.like
    actorsCount = Math.max actorsCount, actorsPreview.length

    linkCount = switch
      when actorsCount > 3 then 2
      else actorsPreview.length

    for i in [0..linkCount - 1]
      @addSubView new ProfileLinkView null, accounts[i]
      @addTextElement partial: @getSeparatorPartial actorsCount, linkCount, i

    if (diff = actorsCount - linkCount) > 0
      @addShowMoreLink diff

    @addTextElement partial: ' liked this.'

    @show()


  getSeparatorPartial: (actorsCount, linkCount, index) ->

    switch
      when (linkCount - index) is (if actorsCount - linkCount then 1 else 2)
        ' and '
      when index < (linkCount - 1)
        ', '


  addShowMoreLink: (diff) ->

    text = " other#{if diff > 1 then 's' else ''}"

    @addSubView new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'profile'
      partial    : "<strong>#{diff} #{text}</strong>"
      attributes : href: '#'
      click      : @bound 'showLikers'


  addTextElement: (options = {}, data) ->
    options.tagName = 'span'
    @addSubView new KDCustomHTMLView options, data


  viewAppended: ->

    super

    @updateActors()
