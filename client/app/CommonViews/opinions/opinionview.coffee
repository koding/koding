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
      subItemClass  : OpinionListItemView
      delegate      : @
    , data

    @opinionController = new OpinionListViewController view: @opinionList
    @opinionHeader = new OpinionViewHeader delegate: @opinionList, data

    @addSubView @opinionList
    @addSubView @opinionHeader

    @opinionList.on "OwnOpinionHasArrived", ->
      # this would be used in the CommentHeader, if there was one
    @opinionList.on "OpinionIsDeleted", (data)->

    if data.replies
      for reply, i in data.replies when reply? and 'object' is typeof reply
        @opinionList.addItem reply

    @opinionList.emit "BackgroundActivityFinished"

  attachListeners:->
    @listenTo
      KDEventTypes : "DecorateActiveOpinionView"
      listenedToInstance : @opinionList
      callback : @decorateActiveCommentState

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