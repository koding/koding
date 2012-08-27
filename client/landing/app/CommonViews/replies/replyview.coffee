class OpinionView extends KDView

  constructor:(options, data)->

    super

    @setClass "comment-container opinion-container-box"
    @createSubViews data
    @resetDecoration()
    @attachListeners()

  render:->
    @resetDecoration()

  createSubViews:(data)->
    @opinionList = new KDListView
      type          : "comments"
      subItemClass  : OpinionListItemView
      delegate      : @
    , data

    @opinionController          = new OpinionListViewController view: @opinionList
    @addSubView @showMore       = new OpinionViewHeader delegate: @opinionList, data
    @addSubView @opinionList

    @opinionList.on "OwnOpinionHasArrived", ->
      showMore.ownCommentArrived()
    @opinionList.on "OpinionIsDeleted", -> showMore.ownCommentDeleted()

    if data.replies
      for reply, i in data.replies when reply? and 'object' is typeof reply
        @opinionList.addItem reply

    @opinionList.emit "BackgroundActivityFinished"

  attachListeners:->
    @listenTo
      KDEventTypes : "DecorateActiveCommentView"
      listenedToInstance : @opinionList
      callback : @decorateActiveCommentState

    @listenTo
      KDEventTypes : "OpinionLinkReceivedClick"
      listenedToInstance : @opinionList
      callback : (pubInst, event) =>
        @opinionForm.commentInput.setFocus()

    # @opinionList.on "CommentCountClicked", =>
    #   @opinionList.emit "AllOpinionsLinkWasClicked"

    @listenTo
      KDEventTypes : "CommentViewShouldReset"
      listenedToInstance : @opinionList
      callback : @resetDecoration

  resetDecoration:->
    post = @getData()
    if post.repliesCount is 0
      @decorateNoCommentState()
    else
      @decorateCommentedState()

  decorateNoCommentState:->
    @unsetClass "active-comment"
    @unsetClass "commented"
    @setClass "no-comment"

  decorateCommentedState:->
    @unsetClass "active-comment"
    @unsetClass "no-comment"
    @setClass "commented"

  decorateActiveCommentState:->
    @unsetClass "commented"
    @unsetClass "no-comment"
    @setClass "active-comment"

  decorateItemAsLiked:(likeObj)->
    if likeObj?.results?.likeCount > 0
      @setClass "liked"
    else
      @unsetClass "liked"
    @ActivityActionsView.setLikedCount likeObj