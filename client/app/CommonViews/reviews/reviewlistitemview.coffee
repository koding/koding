class ReviewListItemView extends CommentListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "review"
    ,options
    super options,data
