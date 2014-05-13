class CommentLikeView extends ActivityLikeView

  pistachio: ->

    """
    <span class='comment-actions'>
      {{> @likeLink}}{{> @likeCount}}
    </span>
    """
