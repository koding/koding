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
    @editCommentWrapper = new KDCustomHTMLView
      cssClass : "edit-comment-wrapper hidden"

    @editInfo = new KDCustomHTMLView
      tagName: "span"
      cssClass: "hidden edited"
      pistachio: "edited"

    if data.getAt 'editedAt' then @editInfo.show()

    if deleterId? and deleterId isnt originId
      @deleter = new ProfileLinkView {}, data.getAt('deletedBy')

    activity = @getDelegate().getData()
    loggedInId = KD.whoami().getId()

    isCommentMine   = loggedInId is data.originId
    isActivityMine  = loggedInId is activity.originId
    canEditComments = "edit comments" in KD.config.permissions

    settingsOptions = {}
    # if i am the owner of the comment or activity
    # i can delete it
    if isCommentMine or isActivityMine or canEditComments
      settingsOptions.delete = yes
      showSettingsMenu       = yes

    # if i can edit comments(have permission)
    if (isCommentMine and "edit own comments" in KD.config.permissions) or canEditComments
        settingsOptions.edit = yes
        showSettingsMenu     =  yes

    # if settings menu should be visible
    if showSettingsMenu
      @settings = @getSettings data, settingsOptions
    else
      @settings = new KDView

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
        if err
          @hideEditCommentForm data
          new KDNotificationView title: err.message
          return
        data.body = comment
        data.editedAt = new Date
        @hideEditCommentForm(data)

  cancelCommentUpdate: ->
    @hideEditCommentForm(@getData())

  hideEditCommentForm:(data)->
    @settings.show()
    @editComment.destroy()
    @body.show()
    @editInfo.show() if data.getAt 'editedAt'
    @editCommentWrapper.hide()

  showEditCommentForm:(data)->
    @settings.hide()
    @body.hide()
    @editInfo.hide()
    @editComment = new EditCommentForm
      cssClass : 'edit-comment-box'
      editable : yes
      delegate : this,
      data
    @editCommentWrapper.addSubView @editComment
    @editCommentWrapper.show()

  getSettings:(data, options)->
    button = new KDButtonViewWithMenu
      cssClass       : 'activity-settings-menu'
      style          : 'comment-menu'
      itemChildClass : ActivityItemMenuItem
      title          : ''
      icon           : yes
      delegate       : this
      iconClass      : "arrow"
      menu           : @settingsMenu data, options
      callback       : (event)=> button.contextMenu event

  getBody:(data)->
    new KDCustomHTMLView
      cssClass : "comment-body-container"
      pistachio: "{p{@utils.applyTextExpansions #(body), yes}}"
    ,data

  render:->
    if @getData().getAt 'deletedAt'
      @emit 'CommentIsDeleted'
    @updateTemplate()
    super

  viewAppended:->
    @updateTemplate yes
    @template.update()

  click:(event)->
    KD.utils.showMoreClickHandler event
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

  settingsMenu:(data, options={})->
    menu = {}
    if options.edit
      menu['Edit']   = callback : => @showEditCommentForm data
    if options.delete
      menu['Delete'] = callback : => @confirmDeleteComment data
    return menu

  pistachio:->
    """
      {{> @avatar}}
      <div class='comment-contents clearfix'>
        {{> @author}}
        {{> @body}}
        {{> @editCommentWrapper}}
        {{> @editInfo}}
        {{> @settings}}
        {{> @likeView}}
        {{> @replyView}}
        {{> @timeAgoView}}
      </div>
    """
