class PrivateMessageSettingsView extends KDCustomHTMLView

  constructor: (options, data) ->
    super options, data

    data = @getData()

    @settings = new KDButtonViewWithMenu
      title: ''
      cssClass: 'activity-settings-menu'
      itemChildClass: ActivityItemMenuItem
      menu: @bound 'settingMenu'

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
      modal = KDModalView.confirm
        title       : 'Are you sure?'
        description : 'Delete this chat conversation?'
        ok          :
          title     : 'Remove'
          callback  : ->
            { SocialChannel } = KD.remote.api
            channelId = channel.getId()
            modal.destroy()
            SocialChannel.delete({ channelId }).catch KD.showError
