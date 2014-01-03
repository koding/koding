class TeamworkInviteModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-invite-modal"
    options.title    = "Invite someone to your project"
    options.content  = "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor.</p>"
    options.overlay  = yes
    options.width    = 500
    options.buttons  =
      Invite         :
        cssClass     : "modal-clean-green"
        callback     : @bound "sendInvites"
      Cancel         :
        cssClass     : "modal-cancel"
        callback     : @bound "destroy"

    super options, data

    @createInviteView()

  createInviteView: ->
    @completedItems = new KDView
      cssClass : "completed-items"

    @userController       = new KDAutoCompleteController
      form                : new KDFormView
      placeholder         : "Type a username to search "
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : @completedItems
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback) =>
        {inputValue} = args
        blacklist    = (data.getId() for data in @userController.getSelectedItemData())
        blacklist.push KD.whoami()._id
        KD.remote.api.JAccount.byRelevance inputValue, {blacklist}, (err, accounts) =>
          callback accounts

    @addSubView @userController.getView()
    @addSubView @completedItems

  sendInvites: ->
    accounts  = @userController.getSelectedItemData()
    usernames = []
    usernames.push account.profile.nickname for account in accounts
    @getDelegate().input.setValue "invite #{usernames.join ' '}"
    @getDelegate().createMessage()
    @destroy()
