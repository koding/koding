class CommentListItemView extends KDListItemView
  constructor:(options,data)->
    options = $.extend
      type      : "comment"
      cssClass  : "kdlistitemview kdlistitemview-comment"
    ,options
    super options,data

    data = @getData()

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin = {
      constructorName  : originType
      id               : originId
    }
    @avatar = new AvatarView {
      size    : {width: 30, height: 30}
      origin
    }
    @author = new ProfileLinkView {
      origin
    }

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')
    # if data.originId is KD.whoami().getId()
    #   @settingsButton = new KDButtonViewWithMenu
    #     style       : 'transparent activity-settings-context'
    #     cssClass    : 'activity-settings-menu'
    #     title       : ''
    #     icon        : yes
    #     delegate    : @
    #     iconClass   : "cog"
    #     menu        : [
    #       type      : "contextmenu"
    #       items     : [
    #         { title : 'Delete', id : 2,  parentId : null, callback : => data.delete (err)=> @propagateEvent KDEventType: 'CommentIsDeleted' }
    #       ]
    #     ]
    #     callback    : (event)=> @settingsButton.contextMenu event
    # else
    @deleteLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        href      : '#'
      cssClass    : 'delete-link hidden'

    activity = @getDelegate().getData()
    bongo.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin
        @deleteLink.unsetClass "hidden"
        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteLink
          callback           : => @confirmDeleteComment data

    @likeCount    = new ActivityLikeCount
      tooltip     :
        gravity   : "se"
        title     : ""
        engine    : "tipsy" # We should force to use tipsy because
                            # for now only tipsy supports tooltip updates
      attributes  :
        href      : "#"
        title     : "Click to view..."
      click       : =>
        if data.meta.likes > 0 # 3
          data.fetchLikedByes {},
            sort  : timestamp : -1
            , (err, likes) =>
              new FollowedModalView {title:"Members who liked <cite>#{data.body}</cite>"}, likes
      , data

    @likeCount.on "countChanged", (count) =>
      @updateLikeState yes

    @likeLink     = new ActivityActionLink

  updateLikeState:(checkIfILiked = no)->

    data = @getData()

    if data.meta.likes is 0
      @likeLink.updatePartial "Like"
      return

    data.fetchLikedByes {},
      limit : if checkIfILiked then data.meta.likes else 3
      sort  : timestamp : -1

      , (err, likes) =>

        peopleWhoLiked   = []

        if likes
          if checkIfILiked
            {_id}       = KD.whoami()
            likedBefore = likes.filter((item)-> item._id is _id).length > 0

          likes.forEach (item)=>
            if peopleWhoLiked.length < 3
              {firstName, lastName} = item.profile
              peopleWhoLiked.push "<strong>" + firstName + " " + lastName + "</strong>"
            else return

          if data.meta.likes is 1
            tooltip = peopleWhoLiked[0]
          else if data.meta.likes is 2
            tooltip = peopleWhoLiked[0] + " and " + peopleWhoLiked[1]
          else if data.meta.likes is 3
            tooltip = peopleWhoLiked[0] + ", " + peopleWhoLiked[1] + " and " + peopleWhoLiked[2]
          else
            tooltip = peopleWhoLiked[0] + ", " + peopleWhoLiked[1] + " and <strong>" + (data.meta.likes - 2) + " more.</strong>"

          @likeCount.updateTooltip {title: tooltip }

          if checkIfILiked
            @likeLink.updatePartial if likedBefore then "Unlike" else "Like"

  render:->
    if @getData().getAt 'deletedAt'
      @emit 'CommentIsDeleted'
    @setTemplate @pistachio()
    super

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    # super unless @_partialUpdated

  click:(event)->
    if $(event.target).is("span.collapsedtext a.more-link")
      @$("span.collapsedtext").addClass "show"
      @$("span.collapsedtext").removeClass "hide"

    if $(event.target).is("span.collapsedtext a.less-link")
      @$("span.collapsedtext").removeClass "show"
      @$("span.collapsedtext").addClass "hide"

    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin

  confirmDeleteComment:(data)->
    {type} = @getOptions()
    modal = new KDModalView
      title          : "Delete #{type}"
      content        : "<div class='modalformline'>Are you sure you want to delete this #{type}?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            data.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              # unless err then @emit 'CommentIsDeleted'
              # else
              if err then new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"
        # cancel       :
        #   style      : "modal-cancel"
        #   callback   : => modal.destroy()

  pistachio:->
    {type} = @getOptions()
    if @getData().getAt 'deletedAt'
      @setClass "deleted"
      if @deleter
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted by {{> @deleter}}.</span></div>"
      else
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted.</span></div>"
    else
      """
      <div class='item-content-comment clearfix'>
        <span class='avatar'>{{> @avatar}}</span>
        <div class='comment-contents clearfix'>
          {{> @deleteLink}}
          <p class='comment-body'>
            {{> @author}}
            {{@utils.applyTextExpansions #(body), yes}}
          </p>
          <time>{{$.timeago #(meta.createdAt)}}</time>
        </div>
      </div>
      """
