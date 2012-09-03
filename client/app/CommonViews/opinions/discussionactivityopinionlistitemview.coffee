class DiscussionActivityOpinionListItemView extends KDListItemView

  constructor:(options,data)->
    options = $.extend
      type      : "opinion"
      cssClass  : "kdview kdlistitemview kdlistitemview-activity-opinion"
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

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()


  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin

  shortenedText: (text)->
    if text.length>200
      return text.substr(0,200)+" ..."
    else
      return text

  pistachio:->
    """
      <div class='activity-opinion item-content-comment'>
        <div class="comment-contents">
        <p class="comment-body">{{@utils.expandUsernames @utils.applyMarkdown @shortenedText #(body)}}</p>
        {{> @author}},
        <time>{{$.timeago #(meta.createdAt)}}</time>
      </div>
    </div>
    """
