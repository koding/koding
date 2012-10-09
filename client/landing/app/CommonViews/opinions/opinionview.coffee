class OpinionView extends KDView

  constructor:(options, data)->
    super

    @setClass "opinion-container opinion-container-box"
    @createSubViews data
    @resetDecoration()
    @attachListeners()

  render:->
    @resetDecoration()

  createSubViews:(data)->
    @opinionList = new KDListView
      type          : "opinions"
      itemClass  : OpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList
    @opinionHeader = new OpinionViewHeader delegate: @opinionList, data

    @addSubView @opinionList
    @addSubView @opinionHeader

    @opinionList.on "OwnOpinionHasArrived", ->
    @opinionList.on "OpinionIsDeleted", (data)->

    @opinionList.on "DiscussionTeaserShouldRefresh", =>
      @opinionController.fetchTeaser ->

    if data.opinions
      for opinion, i in data.opinions when opinion? and 'object' is typeof opinion
        @opinionList.addItem opinion

    @opinionList.emit "BackgroundActivityFinished"

  attachListeners:->
    @opinionList.on "DecorateActiveOpinionView", =>
      @decorateActiveCommentState

    @opinionList.on "OpinionLinkReceivedClick", =>
      @parent?.opinionForm?.opinionBody?.setFocus()


    @opinionList.on "OpinionCountClicked", =>
      @opinionList.emit "AllOpinionsLinkWasClicked"

    @listenTo
      KDEventTypes : "OpinionViewShouldReset"
      listenedToInstance : @opinionList
      callback : @resetDecoration

  resetDecoration:->
    post = @getData()
    if post.repliesCount is 0
      @decorateNoCommentState()
    else
      @decorateCommentedState()

  decorateNoCommentState:->
    @unsetClass "active-opinion"
    @unsetClass "opinionated"
    @setClass "no-opinion"

  decorateCommentedState:->
    @unsetClass "active-opinion"
    @unsetClass "no-opinion"
    @setClass "opinionated"

  decorateActiveCommentState:->
    @unsetClass "opinionated"
    @unsetClass "no-opinion"
    @setClass "active-opinion"

  decorateItemAsLiked:(likeObj)->
    if likeObj?.results?.likeCount > 0
      @setClass "liked"
    else
      @unsetClass "liked"
    @ActivityActionsView.setLikedCount likeObj