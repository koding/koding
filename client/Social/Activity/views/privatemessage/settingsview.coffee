class PrivateMessageSettingsView extends KDCustomHTMLView

  constructor: (options, data) ->
    super options, data

    data = @getData()

    @settings = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'activity-settings-menu'
      itemChildClass : ActivityItemMenuItem
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'

    @menu = {}

    @addSubView @settings

  viewAppended: ->
    if KD.checkFlag('super-admin') or KD.isMyChannel @getData()
      @addSubView @settings

  addMenuItem: (title, callback) -> @menu[title] = {callback}

  settingsMenu: ->

    channel = @getData()

    @addMenuItem 'Leave Conversation', =>
      @leaveModal = KDModalView.confirm
        title        : 'Are you sure?'
        description  : 'Other participants in this chat will see that you have left and you will stop receiving further notifications.'
        ok           :
          title      : 'Leave'
          callback   : @bound 'leaveConversation'

    @menu

  leaveConversation: ->
    @prepareModal @leaveModal

    channelId = @getData().getId()

    {channel} = KD.singletons.socialapi
    channel.leave {channelId}, (err) =>
      return @handleModalError @leaveModal, err if err?

      @emit "LeftChannel"
      @leaveModal.destroy()
      KD.singletons.router.handleRoute '/Activity/Public'

  prepareModal: (modal) ->
    confirmButton = modal.buttons['OK']
    confirmButton.showLoader()

  handleModalError: (modal, err) ->
    confirmButton = modal.buttons['OK']
    confirmButton.hideLoader()
    modal.destroy()
    KD.showError err

