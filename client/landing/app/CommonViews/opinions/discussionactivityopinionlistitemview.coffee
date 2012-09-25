class DiscussionActivityOpinionListItemView extends KDListItemView

  constructor:(options,data)->
    options = $.extend
      type      : "opinion"
      cssClass  : "kdlistitemview-activity-opinion"
      tooltip     :
        title     : "Answer"
        offset    : 3
        selector  : "span.type-icon"
    ,options

    super options,data

    data = @getData()

    data.on "OpinionIsDeleted",(opinion)=>

      # removing opinion from the data until teaser is refreshed
      opinions = @parent.getData().opinions
      i = opinions.indexOf data
      opinions.splice i,1

      #removing item from the view
      @destroy()

    @actionLinks = new OpinionActivityActionsView
      delegate : @
      cssClass : "reply-header"
    , data

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @author = new ProfileLinkView {
      origin
    }

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 30, height: 30}
      origin  : origin

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin
    else
      appManager.tell "Activity", "createContentDisplay", @parent.getData()

  shortenedText: (text)->
    if text.length>200
      return text.substr(0,200)+" ..."
    else
      return text

  pistachio:->
    """
      <div class='activity-opinion item-content-comment'>
        <span class="avatar">{{> @avatar}}</span>
        <div class="comment-contents">
          <p class="comment-body has-markdown force-small-markdown">{{@shortenedText @utils.expandUsernames @utils.applyMarkdown #(body)}}</p>
        </div>
        <footer class="activity-opinion-item-footer">
          <span class='type-icon'></span> answer by {{> @author}}
         <time>{{$.timeago #(meta.createdAt)}}</time>
         {{>@actionLinks}}
        </footer>
    </div>
    """
