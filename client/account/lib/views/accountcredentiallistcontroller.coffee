kd                          = require 'kd'
KDView                      = kd.View
KDButtonView                = kd.ButtonView
KDContextMenu               = kd.ContextMenu
KDNotificationView          = kd.NotificationView
KDFormViewWithFields        = kd.FormViewWithFields
KDAutoCompleteController    = kd.AutoCompleteController

KodingSwitch                = require 'app/commonviews/kodingswitch'
AccountListViewController   = require 'account/controllers/accountlistviewcontroller'
MemberAutoCompleteItemView  = require 'app/commonviews/memberautocompleteitemview'
MemberAutoCompletedItemView = require 'app/commonviews/memberautocompleteditemview'

remote                      = require('app/remote').getInstance()
globals                     = require 'globals'
showError                   = require 'app/util/showError'


module.exports = class AccountCredentialListController extends AccountListViewController


  constructor: (options = {}, data) ->

    options.limit               or= 30
    options.noItemFoundText      ?= "You don't have any credentials"

    super options, data

    @filterStates =
      skip  : 0
      busy  : no
      query : {}


  followLazyLoad: ->

    @on 'LazyLoadThresholdReached', kd.utils.debounce 300, =>

      return  @hideLazyLoader()  if @filterStates.busy

      @filterStates.busy  = yes
      @filterStates.skip += @getOption 'limit'

      @fetch @filterStates.query, (err, credentials) =>
        @hideLazyLoader()

        if err or not credentials
          return @filterStates.busy = no

        @instantiateListItems credentials
        @filterStates.busy = no
      , { skip : @filterStates.skip }


  loadItems: ->

    @removeAllItems()
    @showLazyLoader()

    { query, provider, requiredFields } = @getOptions()

    @filterStates.query.provider ?= provider        if provider
    @filterStates.query.fields   ?= requiredFields  if requiredFields

    @fetch @filterStates.query, (err, credentials) =>

      if provider? and credentials?.length is 0
        @showAddCredentialFormFor provider

      @hideLazyLoader()
      @instantiateListItems credentials


  fetch: (query, callback, options = {}) ->

    { JCredential } = remote.api

    options.limit or= @getOption 'limit'
    options.sort    = "meta.modifiedAt": -1

    JCredential.some @filterStates.query, options, (err, credentials) =>

      if err
        @hideLazyLoader()
        showError err, \
          KodingError : "Failed to fetch data, try again later."
        return

      callback err, credentials


  filterByProvider: (query = {}) ->

    @filterStates.skip = 0

    @removeAllItems()
    @showLazyLoader no

    @filterStates.query = query

    @fetch @filterStates.query, (err, credentials) =>

      @hideLazyLoader()
      @instantiateListItems credentials


  loadView: ->

    super

    @listView.on 'ShowShareCredentialFormFor', @bound 'showShareCredentialFormFor'
    @listView.on 'ItemDeleted', (item) =>
      @removeItem item
      @noItemView.show()  if @listView.items.length is 0

    { provider, requiredFields, dontShowCredentialMenu } = @getOptions()

    if provider
      @createAddDataButton()
    else
      @createAddCredentialMenu()  unless dontShowCredentialMenu

    @loadItems()
    @followLazyLoad()


  createAddDataButton: ->

    @getView().parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Create New'
      icon      : yes
      callback  : @lazyBound 'showAddCredentialFormFor', @getOption 'provider'


  createAddCredentialMenu: ->

    Providers    = globals.config.providers
    providerList = { }

    Object.keys(Providers).forEach (provider) =>

      return  if provider is 'custom'
      return  if Object.keys(Providers[provider].credentialFields).length is 0

      providerList[Providers[provider].title] =
        callback : =>
          @_addButtonMenu.destroy()
          @showAddCredentialFormFor provider

    @getView().parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Add new credentials'
      icon      : yes
      callback  : =>
        @_addButtonMenu = new KDContextMenu
          delegate    : addButton
          y           : addButton.getY() + 35
          x           : addButton.getX() + addButton.getWidth() / 2 - 120
          width       : 240
        , providerList

        @_addButtonMenu.setCss 'z-index': 10002


  showAddCredentialFormFor: (provider) ->

    { requiredFields, defaultTitle } = @getOptions()

    view = @getView().parent
    view.form?.destroy()
    view.intro?.destroy()

    view.setClass "form-open"

    options   = { provider }
    options.defaultTitle   = defaultTitle    if defaultTitle?
    options.requiredFields = requiredFields  if requiredFields?

    if provider is 'aws'
      view.addSubView view.intro = new kd.CustomHTMLView
        cssClass  : 'credential-creation-intro'
        partial   : '''
          <p>Add your AWS credentials</a>
          <ol>
            <li>Create an AWS user</li>
            <li>Attach the AdministratorAccess policy</li>
            <li>Add the Access Key ID and Secret here</li>
          </ol>
          <p>Need some help? <a href='http://learn.koding.com/aws-provider-setup'>Follow our guide</a>
          '''

    { ui }    = kd.singletons.computeController
    view.form = ui.generateAddCredentialFormFor options
    view.form.setClass 'credentials-form-view'

    view.form.on "Cancel", ->
      view.unsetClass "form-open"
      view.form.destroy()

    view.form.on "CredentialAdded", (credential) =>
      view.unsetClass "form-open"
      credential.owner = yes
      view.form.destroy()
      @addItem credential

    view.addSubView view.form


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
