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
        callback       : (event)=> button.contextMenu event
    else
      new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'

    activityController = KD.getSingleton('activityController')

  settingsMenu:(post)->
    account        = KD.whoami()
    if post.originId is account.getId()
      menu =
        'Edit'     :
          callback : =>
            @emit 'ActivityEditIsClicked'
            # KD.getSingleton("appManager").tell "Activity", "editActivity", post
        'Delete'   :
          callback : =>
            @confirmDeletePost post

      return menu

    if KD.checkFlag("super-admin") or KD.hasAccess("delete posts")
      if KD.checkFlag 'exempt', account
        menu =
          'Unmark User as Troll' :
            callback             : ->
              activityController.emit "ActivityItemUnMarkUserAsTrollClicked", post
      else
        menu =
          'Mark User as Troll' :
            callback           : ->
              activityController.emit "ActivityItemMarkUserAsTrollClicked", post

      menu['Delete Post'] =
        callback : =>
          @confirmDeletePost post

      menu['Block User'] =
        callback : ->
          activityController.emit "ActivityItemBlockUserClicked", post.originId

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


