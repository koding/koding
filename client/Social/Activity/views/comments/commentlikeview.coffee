class CommentLikeView extends ActivityLikeView

  constructor: ->

    super

    @likeLink.updatePartial "Like"


  pistachio: ->

    """
    <span class='comment-actions'>
      {{> @likeLink}}{{> @likeCount}}
    </span>
    """
