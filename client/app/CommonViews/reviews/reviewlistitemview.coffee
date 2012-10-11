class ReviewListItemView extends CommentListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "review"
    ,options
    super options,data

  pistachio:->
    """
    <div class='item-content-review clearfix'>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='review-contents clearfix'>
        <p class='review-body'>
          {{@utils.applyTextExpansions #(body), yes}}
        </p>
        {{> @deleteLink}}
        <span class='footer'>
          <time>{{> @author}} reviewed {{$.timeago #(meta.createdAt)}}</time>
          {{> @likeView}}
        </span>
      </div>
    </div>
    """