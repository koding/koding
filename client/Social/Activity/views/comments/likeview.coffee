class CommentLikeView extends ActivityLikeView

  constructor : (options = {}, data) ->

    super options, data

  pistachio: ->

    '''
    {{> @link}}{{> @count}}
    '''
