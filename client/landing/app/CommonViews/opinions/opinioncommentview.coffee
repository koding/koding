class OpinionCommentView extends KDView

  constructor:(options, data)->

    super

    @setClass "comment-container"
    @createSubViews data
    @resetDecoration()
    @attachListeners()

  render:->
    @resetDecoration()

  createSubViews:(data)->
    @commentList = new KDListView
      type          : "comments"
      itemClass  : OpinionCommentListItemView
      delegate      : @
    , data

    @commentController        = new CommentListViewController view: @commentList
    @addSubView showMore      = new CommentViewHeader
      delegate          : @commentList
      maxCommentToShow  : 10000
    , data
    @addSubView @commentList
    @addSubView @commentForm  = new NewCommentForm delegate : @commentList

    @commentList.on "OwnCommentHasArrived", ->
      showMore.ownCommentArrived()
      @getDelegate().emit "DiscussionTeaserShouldRefresh"

    @commentList.on "CommentIsDeleted", -> showMore.ownCommentDeleted()

    if data.replies
      for reply in data.replies when reply? and 'object' is typeof reply
        @commentList.addItem reply

    @commentList.emit "BackgroundActivityFinished"

  attachListeners:->
    @commentList.on "DecorateActiveCommentView", @bound "decorateActiveCommentState"

    @commentList.on "CommentLinkReceivedClick", (event) =>
      @commentForm.commentInput.setFocus()

    @commentList.on "CommentCountClicked", =>
      @commentList.emit "AllCommentsLinkWasClicked"
      @commentForm.commentInput.setFocus()

    @commentList.on "CommentViewShouldReset", @bound "resetDecoration"

  resetDecoration:->
    post = @getData()
    if @commentList.items.length is 0
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
