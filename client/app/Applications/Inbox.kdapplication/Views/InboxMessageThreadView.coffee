class InboxMessageThreadView extends CommentView
  constructor:(options, data)->
    super
    @unsetClass "comment-container"
    @setClass "thread-container"
  
  createSubViews:(data)->

    @commentList = new KDListView
      type          : "comments"
      subItemClass  : InboxMessageReplyView
      delegate      : @
    , data

    @commentListViewController = new CommentListViewController 
      view: @commentList
    , data
    
    
    @addSubView showMore = new InboxShowMoreLink delegate: @commentList, data
    showMore.unsetClass "show-more-comments"
    showMore.setClass "show-more"
    @addSubView @commentList
    # @addSubView @commentForm = new InboxReplyForm delegate : @commentList
    
    if data.replies
      for reply in data.replies when reply? and 'object' is typeof reply
        @commentList.addItem reply
        log reply.meta.createdAt, 'gjskhdfkgs'

    @commentList.emit "BackgroundActivityFinished"

