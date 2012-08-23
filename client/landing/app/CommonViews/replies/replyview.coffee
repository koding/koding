class ReplyView extends CommentView
  constructor:->
    super

  createSubViews:(data)->
    log "reply is in ", data
    @commentList = new KDListView
      type          : "comments"
      subItemClass  : CommentListItemView
      delegate      : @
    , data

    @commentController        = new CommentListViewController view: @commentList
    @addSubView showMore      = new CommentViewHeader delegate: @commentList, data
    @addSubView @commentList
    @addSubView @commentForm  = new NewCommentForm delegate : @commentList

    @commentList.on "OwnCommentHasArrived", -> showMore.ownCommentArrived()
    @commentList.on "CommentIsDeleted", -> showMore.ownCommentDeleted()

    log "adding replies from", data.replies

    if data.replies
      for reply in data.replies when reply? and 'object' is typeof reply
        log "adding reply"
        @commentList.addItem reply

    @commentList.emit "BackgroundActivityFinished"

  attachListeners:->

    @listenTo
      KDEventTypes : "DecorateActiveCommentView"
      listenedToInstance : @commentList
      callback : @decorateActiveCommentState

    @listenTo
      KDEventTypes : "CommentLinkReceivedClick"
      listenedToInstance : @commentList
      callback : (pubInst, event) =>
        @commentForm.commentInput.setFocus()

    @commentList.on "CommentCountClicked", =>
      @commentList.emit "AllCommentsLinkWasClicked"

    @listenTo
      KDEventTypes : "CommentViewShouldReset"
      listenedToInstance : @commentList
      callback : @resetDecoration