class AdministrationView extends KDTabViewWithForms

  constructor:(options, data)->

    options =
      navigable             : yes
      goToNextFormOnSubmit  : no
      forms                 :
        "User Details"      :
          buttons           :
            Update          :
              title         : "Update"
              style         : "solid medium green"
              loader        : yes
              callback      : =>
                {inputs, buttons} = @forms["User Details"]
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  account  = accounts[0]
                  flags    = (flag.trim() for flag in inputs.Flags.getValue().split ",")
                  account.updateFlags flags, (err)->
                    error err if err
                    new KDNotificationView
                      title: if err then "Failed!" else "Done!"
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
            BlockUser       :
              label         : "Block User"
              itemClass     : KDButtonView
              title         : "Block"
              callback      : =>
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  activityController = KD.getSingleton('activityController')
                  activityController.emit "ActivityItemBlockUserClicked", accounts[0].profile.nickname
                else
                  new KDNotificationView {title: "Please select an account!"}
            VerifyEmail     :
              label         : "Verify Email Address"
              itemClass     : KDButtonView
              title         : "Verify Email Address"
              callback      : =>
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  KD.remote.api.JAccount.verifyEmailByUsername accounts.first.profile.nickname, (err, res)->
                    title = if err then err.message else "Confirmed"
                    new KDNotificationView {title}
                else
                  new KDNotificationView {title: "Please select an account!"}

            Impersonate     :
              label         : "Switch to User "
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
                        color    : "#444444"
                      callback   : =>
                        accounts = @userController.getSelectedItemData()
                        unless accounts.length is 0
                          KD.impersonate accounts[0].profile.nickname, =>
                            modal.destroy()
                        else
                          modal.destroy()

        "Broadcast Message" :
          buttons           :
            "Broadcast Message"  :
              title         : "Broadcast"
              style         : "solid medium green"
              loader        : yes

              callback      : (event)=>
                {inputs, buttons} = @forms["Broadcast Message"]

                KD.remote.api.JSystemStatus.create
                  scheduledAt : Date.now()+inputs.Duration.getValue()*1000
                  title       : inputs.Title.getValue()
                  content     : inputs.Description.getValue()
                  type        : inputs.Type.getValue()
                , (err, status) ->
                  KD.showError err  if err
                  buttons["Broadcast Message"].hideLoader()

          fields            :
            Presets         :
              label         : 'Use Preset'
              type          : 'select'
              cssClass      : 'preset-select'
              selectOptions :
                [
                  { title   : "No preset selected",  value : "none"   }
                  { title   : "Shutdown in...",    value : "restart"   }
                  { title   : "Please refresh...",     value : "reload"    }
                ]
              defaultValue  : 'none'
              change        : =>
                msgMap      =
                  'none' :
                    title   : ''
                    content : ''
                    duration: 300
                    type    : 'restart'
                  'restart' :
                    title   : 'Shutdown in'
                    content : 'We are upgrading our platform. Please save your work.'
                    duration: 300
                    type    : 'restart'
                  'reload'  :
                    title   : 'Koding is updated!'
                    content : 'Please refresh your browser and enjoy the latest features.'
                    duration: 10
                    type    : 'reload'

                {inputs, buttons} = @forms["Broadcast Message"]
                {title, content, duration, type} = msgMap[inputs.Presets.getValue()]

                inputs.Title.setValue       title
                inputs.Description.setValue content
                inputs.Duration.setValue    duration
                inputs.Type.setValue        type

            Title           :
              label         : "Message Title"
              type          : "text"
              placeholder   : "Shutdown in"
              tooltip       :
                title       : 'When using type "Restart", end title with "in",'+\
                ' since there will be a timer following the title.'
                placement   : 'right'
                direction   : 'center'
                offset      :
                  top       : 2
                  left      : 0
            Description     :
              label         : "Message Details"
              type          : "text"
              placeholder   : "We are upgrading our platform. Please save your work."
            Duration        :
              label         : "Timer duration"
              type          : "text"
              defaultValue  : 5*60
              tooltip       :
                title       : 'in seconds'
                placement   : 'right'
                direction   : 'center'
                offset      :
                  top       : 2
                  left      : 0
              placeholder   : "Please enter a reasonable timeout."
            Type            :
              label         : 'Type'
              type          : 'select'
              cssClass      : 'type-select'
              selectOptions :
                [
                  { title   : "Restart",      value : "restart"   }
                  { title   : "Info Text",    value : "info"  }
                  { title   : "Reload",       value : "reload"    }
                  { title   : "Error",        value : "red"  }
                  { title   : "Warning",      value : "yellow"  }
                  { title   : "Notification", value : "green"  }
                ]
              defaultValue  : 'restart'
              change        : =>
                {inputs, buttons} = @forms["Broadcast Message"]
                type = inputs.Type.getValue()
                inputs['presetExplanation'].updatePartial switch type
                  when 'restart'
                    'This will show a timer.'
                  else
                    'No timer will be shown.'
              nextElement   :
                presetExplanation:
                  cssClass  : 'type-explain'
                  itemClass : KDView
                  partial   : 'This will show a timer.'
        # "Introduction":
        #   fields            : {}

    super options, data

    {inputs, buttons} = @forms["Broadcast Message"]
    preset = inputs.Type.change()

    @hideConnectedFields()

    @createUserAutoComplete()

  createUserAutoComplete:->
    {fields, inputs, buttons} = @forms["User Details"]

    {JAccount} = KD.remote.api

    @userController = new KDAutoCompleteController
      form                : @forms["User Details"]
      name                : "userController"
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : "profile.nickname"
      outputWrapper       : fields.userWrapper
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : "users"
      submitValuesAsText  : yes
      dataSource          : (args, callback)=>
        {inputValue} = args
        if /^@/.test inputValue
          query = 'profile.nickname': inputValue.replace /^@/, ''
          JAccount.one query, (err, account)=>
            if not account
              @userController.showNoDataFound()
            else
              callback [account]
        else
          byEmail = /[^\s@]+@[^\s@]+\.[^\s@]+/.test inputValue
          JAccount.byRelevance inputValue, {byEmail}, (err, accounts)->
            callback accounts

    @userController.on "ItemListChanged", =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0
        account = accounts[0]
        inputs.Flags.setValue account.globalFlags?.join(',')
        userRequestLineEdit.hide()
        @showConnectedFields()
      else
        userRequestLineEdit.show()
        @hideConnectedFields()

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  hideConnectedFields:->
    {fields, inputs, buttons} = @forms["User Details"]
    fields.Impersonate.hide()
    buttons.Update.hide()
    fields.Flags.hide()
    fields.Block.hide()
    inputs.Flags.setValue ''

  showConnectedFields:->
    {fields, inputs, buttons} = @forms["User Details"]
    fields.Impersonate.show()
    fields.Flags.show()
    fields.Block.show()
    buttons.Update.show()

class MemberAutoCompletedItemView extends KDAutoCompletedItem

  JView.mixin @prototype

  viewAppended:->
    @addSubView @profileText = new AutoCompleteProfileTextView {}, @getData()
