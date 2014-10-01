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

    @addMenuItem 'Delete Conversation', ->
      PrivateMessageDeleteModal.create channel
