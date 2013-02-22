class ReviewListItemView extends CommentListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "review"
    ,options
    super options,data

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

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
          {{> @author}} reviewed {{> @timeAgoView}}
          {{> @likeView}}
        </span>
      </div>
    </div>
    """