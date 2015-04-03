_ = require 'lodash'
kd = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView = kd.CustomHTMLView
KDLabelView = kd.LabelView
KDModalView = kd.ModalView
KDNotificationView = kd.NotificationView
ActivityItemMenuItem = require './activityitemmenuitem'
remote = require('app/remote').getInstance()
whoami = require 'app/util/whoami'
getMessageOwner = require 'app/util/getMessageOwner'
showErrorNotification = require 'app/util/showErrorNotification'
impersonate = require 'app/util/impersonate'
checkFlag = require 'app/util/checkFlag'
showError = require 'app/util/showError'
isMyPost = require 'app/util/isMyPost'
tokenizeTag = require 'app/util/tokenizeTag'
KodingSwitch = require 'app/commonviews/kodingswitch'


module.exports = class ActivitySettingsView extends KDCustomHTMLView

  constructor:(options = {}, data={})->

    super options, data

    @menu   = {}
    data    = @getData()
    account = whoami()

    @settings        = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'activity-settings-menu'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      iconClass      : 'arrow'
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'
      callback       : (event) => @settings.contextMenu event

  addMenuItem: (title, callback) -> @menu[title] = {callback}

  addFollowActionMenu: ->

    # {pin, unpin} = kd.singletons.socialapi.channel
    # post = @getData()

    # unless post.isFollowed
    #   title = 'Follow Post'
    #   fn    = pin
    # else
    #   title = 'Unfollow Post'
    #   fn    = unpin

    # @addMenuItem title, ->
    #   messageId = post.getId()
    #   fn {messageId}, (err)->
    #     return showError err  if err
    #     post.isFollowed = not post.isFollowed

    return @menu


  addOwnerMenu: ->

    @addMenuItem 'Edit Post', @lazyBound 'emit', 'ActivityEditIsClicked'
    @addMenuItem 'Delete Post', @bound 'confirmDeletePost'

    return @menu


  addAdminMenu: ->
    post = @getData()

    @addOwnerMenu()

    {activityController} = kd.singletons

    getMessageOwner post, (err, owner) =>
      return showErrorNotification err  if err

      if owner.isExempt
        @addMenuItem 'Unmark User as Troll', ->
          activityController.emit "ActivityItemUnMarkUserAsTrollClicked", post
      else
        @addMenuItem 'Mark User as Troll', ->
          activityController.emit "ActivityItemMarkUserAsTrollClicked", post

      @addMenuItem 'Block User', ->
        activityController.emit "ActivityItemBlockUserClicked", post.account._id
      @addMenuItem 'Impersonate', ->
        impersonate owner.profile.nickname

  settingsMenu: ->

    @menu = {}

    # @addFollowActionMenu()
    @addOwnerMenu()  if isMyPost @getData()
    @addAdminMenu()  if checkFlag('super-admin')

    return @menu


  viewAppended: ->

    data = @getData()

    @addSubView @settings  if _.every [
      not data.isFake
      (isMyPost(data) or checkFlag 'super-admin')
    ], Boolean


  deletePostConfirmed: (modal) ->

    @emit 'ActivityDeleteStarted'
    modal.destroy()
    id = @getData().getId()
    kd.singletons.appManager.tell 'Activity', 'delete', {id}, (err) =>

      if err
        showError err
        @emit 'ActivityDeleteFailed'
      else
        @emit 'ActivityDeleteSucceeded'


  confirmDeletePost: ->

    modal = new KDModalView
      title          : "Delete post"
      content        : "<div class='modalformline'>Are you sure you want to delete this post?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          style      : "solid red medium"
          loader     :
            color    : "#e94b35"
          callback   : => @deletePostConfirmed modal
        Cancel       :
          style      : "solid light-gray medium"
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
          style    : "solid light-gray medium"
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
    {JTag} = remote.api
    JTag.one "slug" : tagto, (err, tag)=>
      if state
        @addTagToPost post, tag
      else
        @removeTagFromPost post, tag

  removeTagFromPost:(activity, tagToRemove)->
    if not tagToRemove
      return new KDNotificationView title : "Tag not found!"

    {tags, body}   = activity
    stringToRemove = tokenizeTag tagToRemove
    body  = body.replace stringToRemove, ""
    index = tags.indexOf tagToRemove
    tags.splice index, 1

    options  =
      body   : body
      meta   : {tags}

    options.feedType = '' if tagToRemove.title is "bug"
    activity.modify options, (err)->
      showError err if err

  addTagToPost : (activity, tagToAdd)->
    if not tagToAdd
      return new KDNotificationView title : "Tag not found!"

    {tags, body} = activity
    newTags      = []
    body         += tokenizeTag tagToAdd

    if tags?.length > 0
      newTags.push id : tag.getId() for tag in tags

    newTags.push id : tagToAdd.getId()

    options  =
      body   : body
      meta   :
        tags : newTags

    options.feedType = 'bug' if tagToAdd.title is "bug"
    activity.modify options, (err)->
      showError err if err


