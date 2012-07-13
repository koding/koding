class ContentDisplayComments extends JView

  constructor:(options, data)->

    super

    @commentView     = new CommentView {}, data    
    @activityActions = new ActivityActionsView
      delegate : @commentView.commentList
      cssClass : "comment-header"
    , data

  pistachio:->

    """
    {{> @activityActions}}
    {{> @commentView}}
    """