class InboxMessageThreadView extends CommentView
  constructor:(options, data)->
    super
    @unsetClass "comment-container"
    @setClass "thread-container"

  createSubViews:(data)->

    @commentList = new KDListView
      type          : "comments"
      itemClass  : InboxMessageReplyView
      delegate      : @
    , data

    @commentController = new CommentListViewController view: @commentList
    @addSubView showMore = new CommentViewHeader
      delegate: @commentList
      itemTypeString: "replies"
    , data

    @commentList.on "OwnCommentHasArrived", -> showMore.ownCommentArrived()
    @commentList.on "CommentIsDeleted", -> showMore.ownCommentDeleted()

    showMore.unsetClass "show-more-comments"
    showMore.setClass "show-more"
    @addSubView @commentList
    # @addSubView @commentForm = new InboxReplyForm delegate : @commentList

    if data.replies
      for reply in data.replies when reply? and 'object' is typeof reply
        @commentList.addItem reply

    @commentList.emit "BackgroundActivityFinished"
