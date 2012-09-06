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
    KD.remote.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin
        @deleteLink.unsetClass "hidden"
        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteLink
          callback           : => @confirmDeleteComment data

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
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      KD.remote.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin

  confirmDeleteComment:(data)->
    modal = new KDModalView
      title          : "Delete comment"
      content        : "<div class='modalformline'>Are you sure you want to delete this comment?</div>"
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
    if @getData().getAt 'deletedAt'
      @setClass "deleted"
      if @deleter
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s comment has been deleted by {{> @deleter}}.</span></div>"
      else
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s comment has been deleted.</span></div>"
    else
      """
      <div class='item-content-comment clearfix'>
        <span class='avatar'>{{> @avatar}}</span>
        <div class='comment-contents clearfix'>
          {{> @deleteLink}}
          <p class='comment-body'>
            {{> @author}}
            {{@utils.applyTextExpansions #(body)}}
          </p>
          <time>{{$.timeago #(meta.createdAt)}}</time>
        </div>
      </div>
      """
