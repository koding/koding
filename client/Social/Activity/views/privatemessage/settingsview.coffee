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

    @addMenuItem 'Leave Conversation', =>
      @leaveModal = KDModalView.confirm
        title        : 'Are you sure?'
        description  : 'Other participants in this chat will see that you have left and you will stop receiving further notifications.'
        ok           :
          title      : 'Leave'
          callback   : @bound 'leaveConversation'

  leaveConversation: ->
    @prepareModal @leaveModal

    channelId = @getData().getId()
    accountIds = [ KD.whoami().getId() ]

    channel.removeParticipants {channelId, accountIds}, (err) =>
      return @handleModalError @leaveModal, err if err?

      @leaveModal.destroy()

  prepareModal: (modal) ->
    confirmButton = modal.buttons['OK']
    confirmButton.showLoader()

  handleModalError: (modal, err) ->
    confirmButton = modal.buttons['OK']
    confirmButton.hideLoader()
    modal.destroy()
    KD.showError err

