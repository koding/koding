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

    # This event comes from the bongo model, when the opinion is removed
    # from the DB and the activities.
    # Right now, it only works on opinions that were already in the snapshot
    # when the page was loaded. Opinions that were added later do not emit
    # this event (or rather the event is emitted yet not caught by this view)

    data.on "OpinionIsDeleted",(opinion)=>

      # removing opinion from the data until snapshot/teaser is refreshed
      opinions = @parent.getData().opinions
      opinionIndex = opinions.indexOf data
      opinions.splice opinionIndex,1

      #removing item from the view
      @destroy()

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @commentCount = new ActivityCommentCount
      tooltip     :
        title     : "Comments"
      click       : (pubInst, event)=>
        # @emit "DiscussionActivityLinkClicked"
    , data

    @author = new ProfileLinkView {
      origin
    }

    @avatar = new AvatarStaticView
      tagName : "span"
      size    : {width: 20, height: 20}
      origin  : origin

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      KD.remote.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin
    else
      appManager.tell "Activity", "createContentDisplay", @parent.getData()

  pistachio:->
    """
      <div class='activity-opinion item-content-comment'>
        <span class="avatar">{{> @avatar}}</span>
        <footer class="activity-opinion-item-footer">
           {{> @author}} posted an answer
         <time>{{$.timeago #(meta.createdAt)}}</time>
         <span class="comment-count">#{if @getData().repliesCount > 0 then @utils.formatPlural(@getData().repliesCount, "Comment") else ""}</span>
        </footer>
    </div>
    """
