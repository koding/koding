kd = require 'kd'
KDAutoCompleteController = kd.AutoCompleteController
KDButtonView = kd.ButtonView
KDModalView = kd.ModalView
KDNotificationView = kd.NotificationView
KDTabViewWithForms = kd.TabViewWithForms
KDView = kd.View
remote = require 'app/remote'
objectToString = require 'app/util/objectToString'
applyMarkdown = require 'app/util/applyMarkdown'
impersonate = require 'app/util/impersonate'
showError = require 'app/util/showError'
MemberAutoCompleteItemView = require 'app/commonviews/memberautocompleteitemview'
MemberAutoCompletedItemView = require 'app/commonviews/memberautocompleteditemview'


module.exports = class AdministrationView extends KDTabViewWithForms

  constructor: (options, data) ->

    options =
      navigable             : yes
      goToNextFormOnSubmit  : no
      forms                 :
        'User Details'      :
          buttons           :
            Update          :
              title         : 'Update'
              style         : 'solid medium green'
              loader        : yes
              callback      : =>
                { inputs, buttons } = @forms['User Details']
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  account  = accounts[0]
                  flags    = (flag.trim() for flag in inputs.Flags.getValue().split ',')
                  account.updateFlags flags, (err) ->
                    kd.error err if err
                    new KDNotificationView
                      title: if err then 'Failed!' else 'Done!'
                    buttons.Update.hideLoader()
                else
                  new KDNotificationView { title : 'Select a user first' }
          fields            :
            Username        :
              label         : 'Search for user:'
              type          : 'hidden'
              nextElement   :
                userWrapper :
                  itemClass : KDView
                  cssClass  : 'completed-items'
            Flags           :
              label         : 'Flags'
              placeholder   : 'no flags assigned'
            BlockUser       :
              label         : 'Block User'
              itemClass     : KDButtonView
              title         : 'Block'
              callback      : =>
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  activityController = kd.getSingleton('activityController')
                  activityController.emit 'ActivityItemBlockUserClicked', accounts[0].profile.nickname
                else
                  new KDNotificationView { title: 'Please select an account!' }
            VerifyEmail     :
              label         : 'Verify Email Address'
              itemClass     : KDButtonView
              title         : 'Verify Email Address'
              callback      : =>
                accounts = @userController.getSelectedItemData()
                if accounts.length > 0
                  remote.api.JAccount.verifyEmailByUsername accounts.first.profile.nickname, (err, res) ->
                    title = if err then err.message else 'Confirmed'
                    new KDNotificationView { title }
                else
                  new KDNotificationView { title: 'Please select an account!' }

            Impersonate     :
              label         : 'Switch to User '
              itemClass     : KDButtonView
              title         : 'Impersonate'
              callback      : =>
                modal = new KDModalView
                  title          : 'Switch to this user?'
                  content        : "<div class='modalformline'>This action will reload Koding and log you in with this user.</div>"
                  height         : 'auto'
                  overlay        : yes
                  buttons        :
                    Impersonate  :
                      style      : 'solid green medium'
                      loader     :
                        color    : '#444444'
                      callback   : =>
                        accounts = @userController.getSelectedItemData()
                        unless accounts.length is 0
                          impersonate accounts[0].profile.nickname, ->
                            modal.destroy()
                        else
                          modal.destroy()
    super options, data

    { inputs, buttons } = @forms['Broadcast Message']

    @hideConnectedFields()

    @createUserAutoComplete()

  createUserAutoComplete: ->
    { fields, inputs, buttons } = @forms['User Details']

    { JAccount } = remote.api

    @userController = new KDAutoCompleteController
      form                : @forms['User Details']
      name                : 'userController'
      itemClass           : MemberAutoCompleteItemView
      itemDataPath        : 'profile.nickname'
      outputWrapper       : fields.userWrapper
      selectedItemClass   : MemberAutoCompletedItemView
      listWrapperCssClass : 'users'
      submitValuesAsText  : yes
      dataSource          : (args, callback) =>
        { inputValue } = args
        if /^@/.test inputValue
          query = { 'profile.nickname': inputValue.replace /^@/, '' }
          JAccount.one query, (err, account) =>
            if not account
              @userController.showNoDataFound()
            else
              callback [account]
        else
          byEmail = /[^\s@]+@[^\s@]+\.[^\s@]+/.test inputValue
          JAccount.byRelevance inputValue, { byEmail }, (err, accounts) ->
            callback accounts

    @userController.on 'ItemListChanged', =>
      accounts = @userController.getSelectedItemData()
      if accounts.length > 0
        account = accounts[0]
        inputs.Flags.setValue account.globalFlags?.join(',')
        userRequestLineEdit.hide()
        @showConnectedFields account
      else
        userRequestLineEdit.show()
        @hideConnectedFields()

    fields.Username.addSubView userRequestLineEdit = @userController.getView()

  hideConnectedFields: ->
    { fields, inputs, buttons } = @forms['User Details']
    fields.Impersonate.hide()
    buttons.Update.hide()
    fields.Flags.hide()
    fields.Block.hide()
    inputs.Flags.setValue ''

    @metaInfo?.destroy()

  showConnectedFields: (account) ->

    { fields, inputs, buttons } = @forms['User Details']
    fields.Impersonate.show()
    fields.Flags.show()
    fields.Block.show()
    buttons.Update.show()

    @metaInfo?.destroy()

    account.fetchMetaInformation (err, info) =>
      return if showError err
      info = objectToString info, { separator: '  ' }
      @addSubView @metaInfo = new KDView
        cssClass : 'has-markdown'
        partial  : applyMarkdown "```json \n#{info}\n```"
