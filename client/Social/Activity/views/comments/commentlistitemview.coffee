class CommentListItemView extends KDListItemView
  constructor:(options,data)->

    options.type     or= "comment"
    options.cssClass or= "kdlistitemview kdlistitemview-comment"

    super options,data

    data = @getData()

    originId    = data.getAt('originId')
    originType  = data.getAt('originType')
    deleterId   = data.getAt('deletedBy')?.getId?()

    origin =
      constructorName  : originType
      id               : originId

    @avatar = new AvatarView {
      size        :
        width       : options.avatarWidth or 40
        height      : options.avatarHeight or 40
      origin
      showStatus  : yes
    }

    @author = new ProfileLinkView { origin }

    @body = @getBody data

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')

    activity = @getDelegate().getData()
    loggedInId = KD.whoami().getId()

    @settings = if loggedInId is data.originId # if comment/review owner
      @getSettings(data)
    else if loggedInId is activity.originId or       # if activity/app owner
            KD.checkFlag "super-admin", KD.whoami()  # if super-admin
      @getDeleteButton(data)
    else
      new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    @likeView = new LikeViewClean { tooltipPosition : 'sw', checkIfLikedBefore: yes }, data

    if loggedInId isnt data.originId
      @replyView = new ActivityActionLink
        cssClass : "action-link reply-link"
        partial  : "Mention"
        click    : (event)=>
          @utils.stopDOMEvent event
          KD.remote.cacheable data.originType, data.originId, (err, res) =>
            @getDelegate().emit 'ReplyLinkClicked', res.profile.nickname
    else
      @replyView = new KDView
        tagName  : "span"

    @timeAgoView = new KDTimeAgoView {}, data.meta.createdAt

    # TODO: ??
    data.on 'ContentMarkedAsLowQuality', @bound 'hide' unless KD.checkFlag 'exempt'
    data.on 'ContentUnmarkedAsLowQuality', @bound 'show'

    @on 'CommentUpdated', @bound 'updateComment'
    @on 'CommentUpdateCancelled', @bound 'cancelCommentUpdate'

  updateComment: (comment="")->
    unless comment.trim() is ""
      data = @getData()
      data.modify comment, (err) =>
        return new KDNotificationView title: err.message if err
        data.body = comment
        @hideEditCommentForm(data)

  cancelCommentUpdate: ->
    @hideEditCommentForm(@getData())

  hideEditCommentForm:(data)->
    @body.destroy()
    @body = @getBody data
    @settings = @getSettings(data)
    @timeAgoView = new KDTimeAgoView {}, data.meta.createdAt
    @updateTemplate yes


  showEditCommentForm:(data)->
    @settings.hide()
    @settings.destroy()
    @body.destroy()
    @body = new EditCommentForm
      editable : yes
      delegate : this,
      data
    @timeAgoView = new KDTimeAgoView {}, data.meta.createdAt
    @updateTemplate yes

  getSettings:(data)->
    button = new KDButtonViewWithMenu
      cssClass       : 'activity-settings-menu'
      itemChildClass : ActivityItemMenuItem
      title          : ''
      icon           : yes
      delegate       : this
      iconClass      : "arrow"
      menu           : @settingsMenu data
      callback       : (event)=> button.contextMenu event

  getBody:(data)->
    new KDCustomHTMLView
      pistachio: "{p{@utils.applyTextExpansions #(body), yes}}",
      data

  getDeleteButton:(data)->
    button = new KDCustomHTMLView
        tagName     : 'a'
        attributes  :
          href      : '#'
        cssClass    : 'delete-link hidden'
        click       : KD.utils.stopDOMEvent
      button.unsetClass "hidden"
      button.on "click", => @confirmDeleteComment data
    return button

  render:->
    if @getData().getAt 'deletedAt'
      @emit 'CommentIsDeleted'
    @updateTemplate()
    super

  viewAppended:->
    @updateTemplate yes
    @template.update()

  click:(event)->

    KD.utils.showMoreClickHandler.call this, event

    if $(event.target).is "span.avatar a, a.user-fullname"
      {originType, originId} = @getData()
      KD.remote.cacheable originType, originId, (err, origin)->
        unless err
          KD.getSingleton('router').handleRoute "/#{origin.profile.nickname}", state:origin
          # KD.getSingleton("appManager").tell "Members", "createContentDisplay", origin

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
                title    : "Error, please try again later!"
        cancel       :
          style      : "modal-cancel"
          callback   : -> modal.destroy()

  updateTemplate:(force = no)->
    # TODO: these pistachios are written in JS, pending a solution
    #  to the problem of statically not being able to find pistachios unless
    #  they are contained inside a property called "pistachio".
    if @getData().getAt 'deletedAt'
      {type} = @getOptions()
      @setClass "deleted"
      if @deleter
        pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted by {{> @deleter}}.</span></div>"
      else
        pistachio = "<div class='item-content-comment clearfix'><span>{{> @author}}'s #{type} has been deleted.</span></div>"
      @setTemplate pistachio
    else if force
      @setTemplate @pistachio()

  settingsMenu:(data)->
    menu =
      'Edit'     :
        callback : => @showEditCommentForm data
      'Delete'   :
        callback : => @confirmDeleteComment data

  pistachio:->
    """
      {{> @avatar}}
      <div class='comment-contents clearfix'>
        {{> @author}}
        {{> @body}}
        {{> @settings}}
        {{> @likeView}}
        {{> @replyView}}
        {{> @timeAgoView}}
      </div>
    """
