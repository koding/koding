class OpinionListItemView extends KDListItemView
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
        title     : "Delete your opinion"
        href      : '#'
      cssClass    : 'delete-link hidden'

    @editLink = new KDCustomHTMLView
      tagName     : 'a'
      attributes  :
        title     : "Edit your opinion"
        href      : '#'
      cssClass    : 'edit-link hidden'

    @commentBox = new CommentView null, data

    @actionLinks = new ActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.meta.tags

    activity = @getDelegate().getData()
    bongo.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin

        @editForm = new OpinionFormView
          title : "edit-opinion"
          cssClass : "edit-opinion-form hidden"
          callback : (data)=>
            @getData().modify data, (err, opinion) =>
              callback? err, opinion
              if err
                new KDNotificationView title : "Your changes weren't saved.", type :"mini"
              else
                # new KDNotificationView title : "modified!"
                @editForm.setClass "hidden"

        , data

        @editLink.unsetClass "hidden"

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @editLink
          callback           : =>
            if @editForm.$().hasClass "hidden"
              @editForm.unsetClass "hidden"
            else
              @editForm.setClass "hidden"






        @deleteLink.unsetClass "hidden"
        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteLink
          callback           : => @conformDeleteOpinion data
      # workaround: how would this be solved better?
      else @editForm = new KDCustomHTMLView

  render:->
    if @getData().getAt 'deletedAt'
      @emit 'OpinionIsDeleted'
    @setTemplate @pistachio()
    super

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()
    # super unless @_partialUpdated

  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin

  conformDeleteOpinion:(data)->
    modal = new KDModalView
      title          : "Delete opinion"
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
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s opinion has been deleted by {{> @deleter}}.</span></div>"
      else
        "<div class='item-content-comment clearfix'><span>{{> @author}}'s opinion has been deleted.</span></div>"
    else
      """
      <div class='item-content-opinion item-content-comment clearfix'>
        <span class='avatar'>{{> @avatar}}</span>
        <div class='comment-contents clearfix'>
          {{> @deleteLink}}
          {{> @editLink}}
          <p class='comment-body'>
            {{> @author}}
          </p>
          <p class='opinion-body comment-body opinion-body-with-markup'>
            {{> @editForm}}
            {{@utils.applyLineBreaks @utils.applyTextExpansions @utils.applyMarkdown #(body)}}
          </p>
          <footer class='clearfix'>
            <div class='type-and-time'>
              <span class='type-icon'></span> by {{> @author}}
              <time>{{$.timeago #(meta.createdAt)}}</time>
              {{> @tags}}
            </div>
            {{> @actionLinks}}
      </footer>
      </div>
      </div>
      <div class='item-content-comment clearfix'>
        <div class='opinion-comment'>
          {{> @commentBox}}
        </div>
      </div>
      """
