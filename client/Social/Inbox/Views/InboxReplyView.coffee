class InboxMessageReplyView extends CommentListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "pm-reply"
      cssClass  : "message-body"
    ,options
    super options,data
    
  pistachio:->
    """
    <section>
      <div class='meta'>
        <span class='author-wrapper'>{{> @author}}</span>
        <span class='time'>{{$.timeago #(meta.createdAt)}}</span>
      </div>
      <div>{{@utils.applyTextExpansions #(body)}}</div>
    </section>
    """
