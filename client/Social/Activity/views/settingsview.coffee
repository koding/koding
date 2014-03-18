class ActivitySettingsView extends KDCustomHTMLView

  constructor:(options = {}, data={})->

    super options, data
    data = @getData()
    account = KD.whoami()
    @settings = if (data.originId is account.getId()) or KD.checkFlag('super-admin') or KD.hasAccess("delete posts")
      button = new KDButtonViewWithMenu
        cssClass       : 'activity-settings-menu'
        itemChildClass : ActivityItemMenuItem
        title          : ''
        icon           : yes
        delegate       : this
        iconClass      : "arrow"
        menu           : @settingsMenu data
        style          : "resurrection"
        callback       : (event)=> button.contextMenu event
    else
      new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    activityController = KD.getSingleton('activityController')

  settingsMenu:(post)->
    account        = KD.whoami()
    activityController = KD.getSingleton("activityController")
    menu = {}
    if post.originId is account.getId()
        menu['Edit Post'] =
          callback: => @emit 'ActivityEditIsClicked'
        menu['Delete Post'] =
          callback: => @confirmDeletePost post

    if KD.checkFlag("super-admin") or KD.hasAccess("delete posts")
      if KD.checkFlag 'exempt', account
        menu['Unmark User as Troll'] =
            callback             : ->
              activityController.emit "ActivityItemUnMarkUserAsTrollClicked", post
      else
        menu['Mark User as Troll'] =
            callback           : ->
              activityController.emit "ActivityItemMarkUserAsTrollClicked", post

      menu['Delete Post'] =
        callback : => @confirmDeletePost post

      menu['Edit Post'] =
        callback : => @emit 'ActivityEditIsClicked'

      menu['Block User'] =
        callback : ->
          activityController.emit "ActivityItemBlockUserClicked", post.originId

      menu['Add System Tag'] =
        callback : => @selectSystemTag post

      menu['Impersonate'] =
        callback : ->
          KD.remote.cacheable post.originType, post.originId, (err, owner) ->
            return KD.showError err  if err
            return KD.showError message: "Account not found"  unless owner
            KD.impersonate owner.profile.nickname

    return menu

  viewAppended: -> @addSubView @settings

  confirmDeletePost:(post)->

    modal = new KDModalView
      title          : "Delete post"
      content        : "<div class='modalformline'>Are you sure you want to delete this post?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>

            if post.fake
              @emit 'ActivityIsDeleted'
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              return

            post.delete (err)=>
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              unless err then @emit 'ActivityIsDeleted'
              else new KDNotificationView
                type     : "mini"
                cssClass : "error editor"
                title     : "Error, please try again later!"
        Cancel       :
          style      : "modal-cancel"
          title      : "cancel"
          callback   : ->
            modal.destroy()

    modal.buttons.Delete.blur()

  selectSystemTag : (post)->
    postSystemTags  = []
    postUserTags    = []

    if post.tags?.length > 0
      postSystemTags = (tag.slug for tag in post.tags when tag.category is "system-tag")
      postUserTags   = (tag.slug for tag in post.tags when tag.category is "user-tag")

    modal = new KDModalView
      title        : "Add tags to status update."
      height       : "auto"
      overlay      : no
      buttons      :
        Cancel     :
          style    : "modal-cancel"
          title    : "cancel"
          callback : ->
            modal.destroy()

    @changeLogTagSwitch = new KodingSwitch
      cssClass          : 'dark'
      defaultValue      : "changelog" in postSystemTags
      callback          : (state) =>
        @tagStateChanged state, "changelog", post

    @bugTagSwitch   = new KodingSwitch
      cssClass      : 'dark'
      defaultValue  : "bug" in postUserTags
      callback      : (state) =>
        @tagStateChanged state, "bug", post

    modal.addSubView new KDLabelView
      title : "ChangeLog"
    modal.addSubView @changeLogTagSwitch

    modal.addSubView new KDLabelView
      title : "Bug"
    modal.addSubView @bugTagSwitch

  tagStateChanged:(state, tagto, post)->
    {JTag} = KD.remote.api
    JTag.one "slug" : tagto, (err, tag)=>
      if state
        @addTagToPost post, tag
      else
        @removeTagFromPost post, tag

  removeTagFromPost:(activity, tagToRemove)->
    if not tagToRemove
      return new KDNotificationView title : "Tag not found!"

    {tags, body}   = activity
    stringToRemove = @utils.tokenizeTag tagToRemove
    body  = body.replace stringToRemove, ""
    index = tags.indexOf tagToRemove
    tags.splice index, 1

    options  =
      body   : body
      meta   : {tags}

    options.feedType = '' if tagToRemove.title is "bug"
    activity.modify options, (err)->
      KD.showError err if err

  addTagToPost : (activity, tagToAdd)->
    if not tagToAdd
      return new KDNotificationView title : "Tag not found!"

    {tags, body} = activity
    newTags      = []
    body         += @utils.tokenizeTag tagToAdd

    if tags?.length > 0
      newTags.push id : tag.getId() for tag in tags

    newTags.push id : tagToAdd.getId()

    options  =
      body   : body
      meta   :
        tags : newTags

    options.feedType = 'bug' if tagToAdd.title is "bug"
    activity.modify options, (err)->
      KD.showError err if err
