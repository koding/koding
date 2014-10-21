class PrivateMessageSettingsView extends KDCustomHTMLView

  constructor: (options, data) ->
    super options, data

    data = @getData()

    @settings = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'activity-settings-menu'
      itemChildClass : ActivityItemMenuItem
      menu           : @bound 'settingMenu'
      style          : 'resurrection'

  viewAppended: ->
    if KD.checkFlag('super-admin') or KD.isMyChannel @getData()
      @addSubView @settings

  settingMenu: ->
    @menu = {}

    if KD.checkFlag('super-admin') or KD.isMyChannel @getData()
      @addDeleteMenu()

    @menu

  addMenuItem: (title, callback) -> @menu[title] = {callback}

  addDeleteMenu: ->
    channel = @getData()

    @addMenuItem 'Delete Conversation', =>
      @deleteModal = KDModalView.confirm
        title        : 'Are you sure'
        content      : 'Delete this conversation?'
        ok           :
          title      : 'Remove'
          callback   : @bound 'deleteConversation'

  deleteConversation: ->
    channel = @getData()
    removeButton = @deleteModal.buttons['OK']
    removeButton.showLoader()

    channelId = channel.getId()

    {channel} = KD.singletons.socialapi

    channel.delete {channelId}, (err) =>
      return KD.showError err if err?

      @deleteModal.destroy()
      KD.singletons.router.handleRoute '/Activity/Public'

