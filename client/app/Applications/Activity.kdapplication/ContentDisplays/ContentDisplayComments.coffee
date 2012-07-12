class ContentDisplayComments extends KDView
  viewAppended:->
    {activity} = @getData()
    # @addSubView (new CommentView null, activity),".topictext"
    commentView = new CommentView null, activity
    activityActions = new ActivityActionsView delegate : commentView.commentList, cssClass : "comment-header",activity
    @addSubView activityActions
    @addSubView commentView
