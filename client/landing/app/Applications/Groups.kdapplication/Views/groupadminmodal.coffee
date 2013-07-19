class GroupAdminModal extends KDModalViewWithForms

  constructor : (options = {}, data) ->

    log 'Data for modal!',data

    options =
      title                   : "Group Administration Panel"
      content                 : "<div class='modalformline'>With great power comes great responsibility. ~ Stan Lee</div>"
      overlay                 : yes
      width                   : 500
      height                  : "auto"
      cssClass                : "admin-kdmodal"
      tabs                    :
        navigable             : yes
        goToNextFormOnSubmit  : no
        forms                 :
          "User Details"      :
            buttons           :
              Update          :
                title         : "Update"
                style         : "modal-clean-gray"
                loader        :
                  color       : "#444444"
                  diameter    : 12
                callback      : =>
                  {inputs, buttons} = @modalTabs.forms["User Details"]
                  accounts = @userController.getSelectedItemData()
                  if accounts.length > 0
                    account  = accounts[0]
                    flags    = [flag.trim() for flag in inputs.Flags.getValue().split(",")][0]
                    account.updateFlags flags, (err)->
                      error err if err
                      KD.remote.api.JInvitation.grantInvitesFromClient
                        username : account.profile.nickname
                        quota    : +inputs.Invites.getValue()
                      , (err)=>
                        console.error err if err
                        new KDNotificationView {title: "Done!"}
                        buttons.Update.hideLoader()
                  else
                    new KDNotificationView {title : "Select a user first"}
            fields            :
              Username        :
                label         : "Dear User"
                type          : "hidden"
                nextElement   :
                  userWrapper :
                    itemClass : KDView
                    cssClass  : "completed-items"
              Flags           :
                label         : "Flags"
                placeholder   : "no flags assigned"
              Invites         :
                label         : "Grant Invites"
                type          : "text"
                placeholder   : "number of invites to add"
                validate      :
                  rules       :
                    regExp    : /\d+/i
                  messages    :
                    regExp    : "numbers only please"
              Impersonate     :
                label         : "Switch to User"
                itemClass     : KDButtonView
                title         : "Impersonate"
                callback      : =>
                  modal = new KDModalView
                    title          : "Switch to this user?"
                    content        : "<div class='modalformline'>This action will reload Koding and log you in with this user.</div>"
                    height         : "auto"
                    overlay        : yes
                    buttons        :
                      Impersonate  :
                        style      : "modal-clean-green"
                        loader     :
                          color    : "#FFF"
                          diameter : 16
                        callback   : =>
                          accounts = @userController.getSelectedItemData()
                          unless accounts.length is 0
                            KD.impersonate accounts[0].profile.nickname, =>
                              modal.destroy()
                          else
                            modal.destroy()


          "Broadcast Restart" :
            buttons           :
              "Broadcast Restart"  :
                title         : "Broadcast"
                style         : "modal-clean-gray"
                callback      : (event)=>
                  {inputs, buttons} = @modalTabs.forms["Broadcast Restart"]

                  KD.remote.api.JSystemStatus.scheduleRestart
                    restartScheduled : Date.now()+inputs.Duration.getValue()*1000
                    restartTitle : inputs.Title.getValue()
                    restartContent : inputs.Description.getValue()
                  ,(stuff)=>

              "Cancel Restart" :
                title         : "Cancel Restart"
                style         : "modal-clean-gray"
                callback      : (event)=>
                  KD.remote.api.JSystemStatus.cancelRestart ->

            fields            :
              Title           :
                label         : "Message Title"
                type          : "text"
                placeholder   : "Shutdown in"
              Description           :
                label         : "Message Details"
                type          : "text"
                placeholder   : "We are upgrading the platform. Please save your work."
              Duration           :
                label         : "Timer duration (in seconds)"
                type          : "text"
                defaultValue  : 5*60
                placeholder   : "Please enter a reasonable timeout."

    super options, data

    @hideConnectedFields()

    @initInviteTab()
    @createUserAutoComplete()

  createUserAutoComplete:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    @userController = new KDAutoCompleteController
      form                : @modalTabs.forms["User Details"]
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : fields.userWrapper
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        blacklist = (data.getId() for data in @userController.getSelectedItemData())
        KD.remote.api.JAccount.byRelevance inputValue, {blacklist}, (err, accounts)=>
          callback accounts

    @userController.on "ItemListChanged", =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0
        account = accounts[0]
        inputs.Flags.setValue account.globalFlags?.join(',')
        userRequestLineEdit.hide()
        @showConnectedFields()
        account.fetchLimit? 'invite', (err, limit)=>
          current = 0
          if not err and limit
            current = limit.quota - limit.usage
          inputs.Invites.setPlaceHolder "Currently has #{current} invites."
      else
        userRequestLineEdit.show()
        @hideConnectedFields()

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  hideConnectedFields:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    fields.Impersonate.hide()
    buttons.Update.hide()
    fields.Invites.hide()
    inputs.Invites.setValue ''
    fields.Flags.hide()
    inputs.Flags.setValue ''

  showConnectedFields:->
    {fields, inputs, buttons} = @modalTabs.forms["User Details"]
    fields.Impersonate.show()
    fields.Flags.show()
    fields.Invites.show()
    inputs.Invites.setPlaceHolder 'Loading...'
    buttons.Update.show()
