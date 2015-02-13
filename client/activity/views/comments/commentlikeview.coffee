class CommentLikeView extends ActivityLikeView

  constructor : (options = {}, data) ->

    super options, data

    @count = new ActivityLikeCount
      cssClass    : 'like-count'
      tooltip     :
        gravity   : @getOption "tooltipPosition"
        title     : ""
    , data
