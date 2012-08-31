class OpinionListItemView extends KDListItemView

  constructor:(options,data)->
    options = $.extend
      type      : "opinion"
      cssClass  : "kdlistitemview kdlistitemview-comment"
    ,options

    super options,data

    data = @getData()

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @avatar = new AvatarView {
      size    :
        width: 50
        height: 50
      origin
    }

    @author = new ProfileLinkView {
      origin
    }

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')

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

    @commentBox = new OpinionCommentView null, data

    @actionLinks = new ActivityActionsView
      delegate : @commentBox.commentList
      cssClass : "comment-header"
    , data

    @tags = new ActivityChildViewTagGroup
      itemsToShow   : 3
      subItemClass  : TagLinkView
    , data.meta.tags

    @smaller = new KDCustomHTMLView
        tagName  : "a"
        cssClass : "opinion-size-link hidden"
        attributes :
          href     : "#"
          title    : "Show less"
        partial    :  "show less"
        click      :=>
          @markup.css "max-height":"300px"
          @larger.show()
          @smaller.hide()

    @larger = new KDCustomHTMLView
        tagName  : "a"
        cssClass : "opinion-size-link hidden"
        attributes :
          href     : "#"
          title    : "Show more"
        partial    :  "show more"
        click      :=>
          @markup.css maxHeight : @textMaxHeight
          @smaller.show()
          @larger.hide()

    @textMaxHeight = 0

    activity = @getDelegate().getData()
    bongo.cacheable data.originId, "JAccount", (err, account)=>
      loggedInId = KD.whoami().getId()
      if loggedInId is data.originId or       # if comment owner
         loggedInId is activity.originId or   # if activity owner
         KD.checkFlag "super-admin", account  # if super-admin

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @editLink
          callback           : =>
            if @editForm?
              @editForm?.destroy()
              delete @editForm
            else
              @editForm = new OpinionFormView
                title : "edit-opinion"
                cssClass : "edit-opinion-form opinion-container"
                callback : (data)=>
                  @getData().modify data, (err, opinion) =>
                    callback? err, opinion
                    if err
                      new KDNotificationView title : "Your changes weren't saved.", type :"mini"
                    else
                      @emit "OwnOpinionWasAdded", opinion
                      @editForm.setClass "hidden"
              , data

              @addSubView @editForm, "p.opinion-body-edit", yes

        @listenTo
          KDEventTypes       : "click"
          listenedToInstance : @deleteLink
          callback           : => @confirmDeleteOpinion data

        @editLink.unsetClass "hidden"
        @deleteLink.unsetClass "hidden"

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    @markup = @$("p.opinion-body-with-markup")
    maxHeight = 300

    if @markup.height()>maxHeight
      @textMaxHeight = @getHeight()
      @markup.css {maxHeight}
      @larger.show()

  click:(event)->
    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      bongo.cacheable originType, originId, (err, origin)->
        unless err
          appManager.tell "Members", "createContentDisplay", origin


  confirmDeleteOpinion:(data)->
    modal = new KDModalView
      title          : "Delete opinion"
      content        : "<div class='modalformline'>Are you sure you want to delete this opinion?</div>"
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
              unless err
                @emit 'OpinionIsDeleted', data
                @destroy()

              if err then new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"

  pistachio:->
    """
    <div class='item-content-opinion clearfix'>
      <span class='avatar'>{{> @avatar}}</span>
        <footer class='opinion-footer clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span> answer written by {{> @author}}
            <time>{{$.timeago #(meta.createdAt)}}</time>
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
      <div class='opinion-contents clearfix'>
        {{> @deleteLink}}
        {{> @editLink}}
        <p class="opinion-body-edit"></p>
        <p class='opinion-body-with-markup'>
          {{@utils.expandUsernames @utils.applyMarkdown #(body)}}
        </p>
        {{>@larger}}
        {{>@smaller}}
    </div>

    </div>
    <div class='item-content-opinion-comments clearfix'>
      <div class='opinion-comment'>
        {{> @commentBox}}
      </div>
    </div>
    """
