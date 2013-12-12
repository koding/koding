class ActivitySettingsView extends KDCustomHTMLView

  constructor:(options = {}, data={})->

    super options, data

    account = KD.whoami()
    @settings = if (data.originId is account.getId()) or KD.checkFlag 'super-admin'
      button = new KDButtonViewWithMenu
        cssClass       : 'activity-settings-menu'
        itemChildClass : ActivityItemMenuItem
        title          : ''
        icon           : yes
        delegate       : @
        iconClass      : "arrow"
        menu           : @settingsMenu data
        callback       : (event)=> button.contextMenu event
    else
      new KDCustomHTMLView tagName : 'span', cssClass : 'hidden'


  settingsMenu:(data)->

    account        = KD.whoami()

    if data.originId is account.getId()
      menu =
        'Edit'     :
          callback : ->
            KD.getSingleton("appManager").tell "Activity", "editActivity", data
        'Delete'   :
          callback : =>
            @confirmDeletePost data

      return menu

    if KD.checkFlag 'super-admin'
      if KD.checkFlag 'exempt', account
        menu =
          'Unmark User as Troll' :
            callback             : ->
              activityController.emit "ActivityItemUnMarkUserAsTrollClicked", data
      else
        menu =
          'Mark User as Troll' :
            callback           : ->
              activityController.emit "ActivityItemMarkUserAsTrollClicked", data

      menu['Delete Post'] =
        callback : =>
          @confirmDeletePost data

      menu['Block User'] =
        callback : ->
          activityController.emit "ActivityItemBlockUserClicked", data.originId

      return menu

  viewAppended: -> @addSubView @settings

  confirmDeletePost:(data)->

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

            if data.fake
              @emit 'ActivityIsDeleted'
              modal.buttons.Delete.hideLoader()
              modal.destroy()
              return

            data.delete (err)=>
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


