kd                          = require 'kd'
KDView                      = kd.View
KDButtonView                = kd.ButtonView
KDContextMenu               = kd.ContextMenu
KDNotificationView          = kd.NotificationView
KDFormViewWithFields        = kd.FormViewWithFields
KDAutoCompleteController    = kd.AutoCompleteController

KodingSwitch                = require 'app/commonviews/kodingswitch'
ComputeController_UI        = require 'app/providers/computecontroller.ui'
AccountListViewController   = require 'account/controllers/accountlistviewcontroller'
MemberAutoCompleteItemView  = require 'app/commonviews/memberautocompleteitemview'
MemberAutoCompletedItemView = require 'app/commonviews/memberautocompleteditemview'

remote                      = require('app/remote').getInstance()
globals                     = require 'globals'
showError                   = require 'app/util/showError'


module.exports = class AccountCredentialListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options.noItemFoundText ?= "You have no credentials."
    super options, data

    @loadItems()


  loadItems: ->

    @removeAllItems()
    @showLazyLoader()

    { JCredential } = remote.api

    JCredential.some {}, { limit: 30 }, (err, credentials) =>

      @hideLazyLoader()

      return if showError err, \
        KodingError : "Failed to fetch credentials, try again later."

      @instantiateListItems credentials


  loadView: ->

    super

    view = @getView()
    view.on "ShowShareCredentialFormFor", @bound "showShareCredentialFormFor"

    {provider} = @getOptions()
    @createAddCredentialMenu()  if not provider?


  createAddCredentialMenu: ->

    Providers    = globals.config.providers
    providerList = { }

    Object.keys(Providers).forEach (provider) =>

      return  if Object.keys(Providers[provider].credentialFields).length is 0

      providerList[Providers[provider].title] =
        callback : =>
          @_addButtonMenu.destroy()
          @showAddCredentialFormFor provider

    @getView().parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Add new credential'
      icon      : yes
      callback  : =>
        @_addButtonMenu = new KDContextMenu
          delegate    : addButton
          y           : addButton.getY() + 35
          x           : addButton.getX() + addButton.getWidth() / 2 - 120
          width       : 240
        , providerList

        @_addButtonMenu.setCss 'z-index': 10002


  showShareCredentialFormFor: (credential) ->

    view = @getView().parent
    view.form?.destroy()

    view.setClass 'share-open'

    view.form           = new KDFormViewWithFields
      cssClass          : "form-view"
      fields            :
        username        :
          label         : "User"
          placeholder   : "Enter group slug or username"
          # type          : "hidden"
          # nextElement   :
          #   userWrapper :
          #     itemClass : KDView
          #     cssClass  : "completed-items"
        owner           :
          label         : "Give ownership"
          itemClass     : KodingSwitch
          defaultValue  : no
      buttons           :
        Save            :
          title         : "Share credential"
          type          : "submit"
          style         : "solid green medium"
          loader        :
            color       : "#444444"
          callback      : -> @hideLoader()
        Cancel          :
          type          : "cancel"
          style         : "solid medium"
          callback      : =>
            view.form.destroy()

            @getView().emit 'sharingFormDestroyed'
            view.unsetClass 'share-open'


      callback          : (data) =>

        { username, owner } = data
        target = username#s.first

        unless target
          return new KDNotificationView
            title : "A user required to share credential with"

        { Save } = view.form.buttons
        Save.showLoader()

        credential.shareWith { target, owner }, (err) =>

          Save.hideLoader()
          view.emit 'sharingFormDestroyed'
          view.unsetClass 'share-open'

          unless showError err
            view.form.destroy()
            @loadItems()


    # {fields, inputs, buttons} = view.form

    # @userController       = new KDAutoCompleteController
    #   form                : view.form
    #   name                : "username"
    #   itemClass           : MemberAutoCompleteItemView
    #   itemDataPath        : "profile.nickname"
    #   outputWrapper       : fields.userWrapper
    #   selectedItemClass   : MemberAutoCompletedItemView
    #   listWrapperCssClass : "users"
    #   submitValuesAsText  : yes
    #   dataSource          : (args, callback) =>
    #     {inputValue} = args
    #     if /^@/.test inputValue
    #       query = 'profile.nickname': inputValue.replace /^@/, ''
    #       remote.api.JAccount.one query, (err, account) =>
    #         if not account
    #           @userController.showNoDataFound()
    #         else
    #           callback [account]
    #     else
    #       remote.api.JAccount.byRelevance inputValue, {}, (err, accounts) ->
    #         callback accounts

    # fields.username.addSubView userRequestLineEdit = @userController.getView()
    # @userController.on "ItemListChanged", (count) ->
    #   userRequestLineEdit[if count is 0 then 'show' else 'hide']()

    view.addSubView view.form


  showAddCredentialFormFor: (provider) ->

    view = @getView().parent
    view.form?.destroy()

    view.setClass "form-open"

    view.form = ComputeController_UI.generateAddCredentialFormFor provider
    view.form.on "Cancel", ->
      view.unsetClass "form-open"
      view.form.destroy()


    view.form.on "CredentialAdded", (credential) =>
      view.unsetClass "form-open"
      credential.owner = yes
      view.form.destroy()
      @addItem credential

    view.addSubView view.form
