class ActivityLikeSummaryView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry "like-summary hidden", options.cssClass

    super options, data

    data
      .on "LikeAdded", @bound "updateActors"
      .on "LikeRemoved", @bound "updateActors"


  showLikers: ->

    {id} = @getData()

    KD.singleton("socialapi").message.listLikers {id}, (err, ids = []) ->

      return KD.showError err  if err
      return  if ids.length is 0

      batch = ids.map do (constructorName = "JAccount") ->
        (id) -> {constructorName, id}

      KD.remote.cacheable batch, (err, accounts) ->

        return KD.showError err  if err
        new ShowMoreDataModalView title: "Likes", accounts


  updateActors: ->

    @fetchPreviewAccounts (err, accounts) =>

      return KD.showError err  if err

      @destroySubViews()
      @refresh accounts


  fetchPreviewAccounts: (callback) ->

    constructorName = "JAccount"
    origins = @getData().interactions.like.actorsPreview.map (id) -> {id, constructorName}

    KD.remote.cacheable origins, callback


  refresh: (accounts = []) ->

    return @hide() if accounts.length is 0

    {actorsCount, actorsPreview} = @getData().interactions.like
    actorsCount = Math.max actorsCount, actorsPreview.length

    linkCount = switch
      when actorsCount > 3 then 2
      else actorsPreview.length

    for i in [0..linkCount - 1]
      @addSubView new ProfileLinkView null, accounts[i]
      @addTextElement partial: @getSeparatorPartial actorsCount, linkCount, i

    if (diff = actorsCount - linkCount) > 0
      @addShowMoreLink actorsCount, linkCount
      @addTextElement partial: " other#{if diff > 1 then 's' else ''}"

    @addTextElement partial: ' liked this.'

    @show()


  getSeparatorPartial: (actorsCount, linkCount, index) ->

    switch
      when (linkCount - index) is (if actorsCount - linkCount then 1 else 2)
        ' and '
      when index < (linkCount - 1)
        ', '


  addShowMoreLink: (actorsCount, linkCount) ->

    @addSubView new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'profile'
      partial    : "<strong>#{actorsCount - linkCount}</strong>"
      attributes : href: '#'
      click      : @bound 'showLikers'


  addTextElement: (options = {}, data) ->
    options.tagName = 'span'
    @addSubView new KDCustomHTMLView options, data


  viewAppended: ->

    super

    @updateActors()
