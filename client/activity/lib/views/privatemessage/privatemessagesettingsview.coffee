kd = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
ActivityItemMenuItem = require '../activityitemmenuitem'
showError = require 'app/util/showError'


module.exports = class PrivateMessageSettingsView extends KDCustomHTMLView

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

  addMenuItem: (title, callback) -> @menu[title] = {callback}

  settingsMenu: ->

    channel = @getData()

    @addMenuItem 'Leave Conversation', =>
      @leaveModal = KDModalView.confirm
        title        : 'Are you sure?'
        description  : 'Other participants in this chat will see that you have left and you will stop receiving further notifications.'
        ok           :
          style      : 'solid medium red'
          title      : 'Leave'
          callback   : @bound 'leaveConversation'
        cancel       :
          style      : 'solid medium light-gray'
          title      : 'cancel'
          callback   : => @leaveModal.destroy()

    @menu

  leaveConversation: ->
    @prepareModal @leaveModal

    channelId = @getData().getId()

    {channel} = kd.singletons.socialapi
    channel.leave {channelId}, (err) =>
      return @handleModalError @leaveModal, err if err?

      @emit "LeftChannel"
      @leaveModal.destroy()
      kd.singletons.router.handleRoute '/Activity/Public'

  prepareModal: (modal) ->
    confirmButton = modal.buttons['OK']
    confirmButton.showLoader()

  handleModalError: (modal, err) ->
    confirmButton = modal.buttons['OK']
    confirmButton.hideLoader()
    modal.destroy()
    showError err
