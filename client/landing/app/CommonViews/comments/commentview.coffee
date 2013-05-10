class CommentView extends KDView

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
      itemClass     : CommentListItemView
      delegate      : @
    , data

    @commentController        = new CommentListViewController view: @commentList
    @addSubView showMore      = new CommentViewHeader delegate: @commentList, data
    @addSubView @commentController.getView()
    @addSubView @commentForm  = new NewCommentForm delegate : @commentList

    @commentList.on 'ReplyLinkClicked', (username) =>
      input = @commentForm.commentInput
      value = input.getValue()
      value = if value.indexOf("@#{username}") >= 0 then value else if value.length is 0 then "@#{username} " else "#{value} @#{username} "

      input.setFocus()
      input.setValue value

    @commentList.on "OwnCommentWasSubmitted", ->
      @getDelegate()?.emit "RefreshTeaser"

    @commentList.on "OwnCommentHasArrived", ->
      showMore.ownCommentArrived()
      @getDelegate()?.emit "RefreshTeaser"

    @commentList.on "CommentIsDeleted", -> showMore.ownCommentDeleted()

    @on "RefreshTeaser",->
      @parent?.emit "RefreshTeaser"

    if data.replies
      for reply in data.replies  when reply? and 'object' is typeof reply
        @commentList.addItem reply

    @commentList.emit "BackgroundActivityFinished"

  attachListeners:->

    @commentList.on "DecorateActiveCommentView", @bound "decorateActiveCommentState"

    @commentList.on "CommentLinkReceivedClick", (event) =>
      @commentForm.makeCommentFieldActive()
      @commentForm.commentInput.setFocus()

    @commentList.on "CommentCountClicked", =>
      @commentList.emit "AllCommentsLinkWasClicked"

    @commentList.on "CommentViewShouldReset", @bound "resetDecoration"

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
