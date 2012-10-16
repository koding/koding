class ReviewView extends KDView

  constructor:(options, data)->

    super

    @setClass "review-container"
    @createSubViews data
    # @resetDecoration()
    @decorateCommentedState()
    @attachListeners()

  render:->
    # FIXME GG
    # @resetDecoration()
    @decorateCommentedState()

  createSubViews:(data)->

    @reviewList = new KDListView
      type          : "comments"
      itemClass     : ReviewListItemView
      delegate      : @
    , data

    @commentController        = new ReviewListViewController view: @reviewList
    @addSubView @commentForm  = new NewReviewForm delegate : @reviewList
    @addSubView showMore      = new CommentViewHeader
      delegate        : @reviewList
      itemTypeString  : 'review'
    , data
    @addSubView @commentController.getView()

    @reviewList.on "OwnCommentHasArrived", -> showMore.ownCommentArrived()
    @reviewList.on "ReviewIsDeleted", -> showMore.ownCommentDeleted()

    data.fetchRelativeReviews limit:3, after:'meta.createdAt', (err, reviews)=>
      for review in reviews
        @reviewList.addItem review

    @reviewList.emit "BackgroundActivityFinished"

  attachListeners:->

    @listenTo
      KDEventTypes : "DecorateActiveCommentView"
      listenedToInstance : @reviewList
      callback : @decorateActiveCommentState

    @listenTo
      KDEventTypes : "CommentLinkReceivedClick"
      listenedToInstance : @reviewList
      callback : (pubInst, event) =>
        @commentForm.commentInput.setFocus()

    @reviewList.on "CommentCountClicked", =>
      @reviewList.emit "AllCommentsLinkWasClicked"

    @listenTo
      KDEventTypes : "CommentViewShouldReset"
      listenedToInstance : @reviewList
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
