class CommentLikeView extends ActivityLikeView

  pistachio: ->

    '''
    <span class='comment-actions''>
    {{> @link}}{{> @count}}
    </span>
    '''
