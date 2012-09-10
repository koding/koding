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
        <footer class="activity-opinion-item-footer">
        <span class='type-icon'></span> answer by {{> @author}} •
        <time>{{$.timeago #(meta.createdAt)}}</time>
        </footer>
        <div class="comment-contents">
        <p class="comment-body">{{@utils.expandUsernames @utils.applyMarkdown @shortenedText #(body)}}</p>
      </div>
    </div>
    """
