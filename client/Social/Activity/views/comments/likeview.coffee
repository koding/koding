class CommentLikeView extends ActivityLikeView

  constructor : (options = {}, data) ->

    super options, data

    @count = new ActivityLikeCount
      cssClass    : 'count'
      tooltip     :
        gravity   : @getOption "tooltipPosition"
        title     : ""
    , data

  pistachio: ->

    '''
    {{> @link}}{{> @count}}
    '''
