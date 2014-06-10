class ActivitySettingsView extends KDCustomHTMLView

  constructor:(options = {}, data={})->

    super options, data

    @menu   = {}
    data    = @getData()
    account = KD.whoami()

    @settings = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'activity-settings-menu'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      iconClass      : 'arrow'
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'
      callback       : (event) => @settings.contextMenu event

    activityController = KD.getSingleton('activityController')


  addMenuItem: (title, callback) -> @menu[title] = {callback}

  addFollowActionMenu: ->

    {pin, unpin} = KD.singletons.socialapi.channel
    post = @getData()

    unless post.isFollowed
      title = 'Follow Post'
      fn    = pin
    else
      title = 'Unfollow Post'
      fn    = unpin

    @addMenuItem title, ->
      messageId = post.getId()
      fn {messageId}, (err)->
        return KD.showError err  if err
        post.isFollowed = not post.isFollowed


    return @menu


  addOwnerMenu: ->

    @addMenuItem 'Edit Post', @lazyBound 'emit', 'ActivityEditIsClicked'
    @addMenuItem 'Delete Post', @bound 'confirmDeletePost'

    return @menu


  addAdminMenu: ->

    post = @getData()

    @menu                = @addOwnerMenu()
    {activityController} = KD.singletons

    if KD.checkFlag 'exempt', KD.whoami()
      @addMenuItem 'Unmark User as Troll', ->
        activityController.emit "ActivityItemUnMarkUserAsTrollClicked", post
    else
      @addMenuItem 'Mark User as Troll', ->
        activityController.emit "ActivityItemMarkUserAsTrollClicked", post

    @addMenuItem 'Block User', ->
      activityController.emit "ActivityItemBlockUserClicked", post.account._id
    @addMenuItem 'Impersonate', ->
      {constructorName, _id} = post.account
      KD.remote.cacheable constructorName, _id, (err, owner) ->
        return KD.showError err  if err
        return KD.showError message: "Account not found"  unless owner
        KD.impersonate owner.profile.nickname

    @addMenuItem 'Add System Tag', => @selectSystemTag post

    return @menu


  settingsMenu: ->

    @menu = {}

    @addFollowActionMenu()
    @addOwnerMenu()  if KD.isMyPost @getData()
    @addAdminMenu()  if KD.checkFlag('super-admin') or KD.hasAccess('delete posts')

    return @menu


  viewAppended: -> @addSubView @settings


  confirmDeletePost: ->

    modal = new KDModalView
      title          : "Delete post"
      content        : "<div class='modalformline'>Are you sure you want to delete this post?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "modal-clean-red"
          loader     :
            color    : "#e94b35"
          callback   : =>

            id = @getData().getId()

            (KD.singleton 'appManager').tell 'Activity', 'delete', {id}, (err) =>

              if err
                new KDNotificationView
                  type     : "mini"
                  cssClass : "error editor"
                  title    : "Error, please try again later!"
                return

              modal.destroy()
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
