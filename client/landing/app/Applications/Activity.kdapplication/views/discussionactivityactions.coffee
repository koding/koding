class DiscussionActivityActionsView extends ActivityActionsView
  constructor : ->
    super

    activity = @getData()

    @replyLink = new ActivityActionLink
      partial  : "Join this discussion"

    @replyCount = new ActivityCommentCount
      tooltip     :
        title     : "Show all"
      click       : =>
        @getDelegate().emit "CommentCountClicked"
    , activity


  pistachio:->

    """
    {{> @loader}}
    {{> @replyLink}}{{> @replyCount}} ·
    <span class='optional'>
    {{> @shareLink}} ·
    </span>
    {{> @likeLink}}{{> @likeCount}}
    """