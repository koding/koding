class AccountCredentialListController extends AccountListViewController

  constructor:(options = {}, data)->

    options.noItemFoundText = "You have no credentials."
    super options, data

    @loadItems()

  loadItems:->

    @removeAllItems()
    @showLazyLoader()

    { JCredential } = KD.remote.api

    JCredential.some {}, { limit: 30 }, (err, credentials)=>

      @hideLazyLoader()

      return if KD.showError err, \
        KodingError : "Failed to fetch credentials, try again later."

      @instantiateListItems credentials

  loadView:->

    super

    view = @getView()
    view.on "ShowShareCredentialFormFor", @bound "showShareCredentialFormFor"

    providerList = { }

    Providers = ComputeController.providers

    Object.keys(Providers).forEach (provider)=>
      providerList[Providers[provider].title] =
        callback : =>
          @_addButtonMenu.destroy()
          @showAddCredentialFormFor provider

    view.parent.prepend addButton = new KDButtonView
      cssClass  : 'add-big-btn'
      title     : 'Add new credential'
      icon      : yes
      callback  : =>
        @_addButtonMenu = new KDContextMenu
          delegate    : addButton
          y           : addButton.getY() + 35
          x           : addButton.getX() + addButton.getWidth() / 2
          width       : 200
        , providerList

  showShareCredentialFormFor: (credential)->

    view = @getView().parent
    view.form?.destroy()

    view.setClass 'share-open'

    view.form           = new KDFormViewWithFields
      cssClass          : "form-view"
      fields            :
        username        :
          label         : "User"
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


      callback          : (data)=>

        log "Here we go", data

        { username, owner } = data
        target = username#s.first

        unless target
          return new KDNotificationView
            title : "A user required to share credential with"

        { Save } = view.form.buttons
        Save.showLoader()

        credential.shareWith { target, owner }, (err)=>

          Save.hideLoader()
          view.emit 'sharingFormDestroyed'
          view.unsetClass 'share-open'

          unless KD.showError err
            view.form.destroy()
            @loadItems()


    {fields, inputs, buttons} = view.form

    # @userController       = new KDAutoCompleteController
    #   form                : view.form
    #   name                : "username"
    #   itemClass           : MemberAutoCompleteItemView
    #   itemDataPath        : "profile.nickname"
    #   outputWrapper       : fields.userWrapper
    #   selectedItemClass   : MemberAutoCompletedItemView
    #   listWrapperCssClass : "users"
    #   submitValuesAsText  : yes
    #   dataSource          : (args, callback)=>
    #     {inputValue} = args
    #     if /^@/.test inputValue
    #       query = 'profile.nickname': inputValue.replace /^@/, ''
    #       KD.remote.api.JAccount.one query, (err, account)=>
    #         if not account
    #           @userController.showNoDataFound()
    #         else
    #           callback [account]
    #     else
    #       KD.remote.api.JAccount.byRelevance inputValue, {}, (err, accounts)->
    #         callback accounts

    # fields.username.addSubView userRequestLineEdit = @userController.getView()
    # @userController.on "ItemListChanged", (count)->
    #   userRequestLineEdit[if count is 0 then 'show' else 'hide']()

    view.addSubView view.form


  showAddCredentialFormFor: (provider)->

    view = @getView().parent
    view.form?.destroy()

    view.setClass "form-open"

    view.form = ComputeController.UI.generateAddCredentialFormFor provider
    view.form.on "Cancel", ->
      view.unsetClass "form-open"
      view.form.destroy()


    view.form.on "CredentialAdded", (credential)=>
      view.unsetClass "form-open"
      credential.owner = yes
      view.form.destroy()
      @addItem credential

    view.addSubView view.form


class AccountCredentialList extends KDListView

  constructor:(options = {}, data)->

    options.tagName  ?= "ul"
    options.itemClass = AccountCredentialListItem

    super options, data

  deleteItem: (item)->

    credential = item.getData()

    modal = KDModalView.confirm
      title       : "Remove credential"
      description : "Do you want to remove ?"
      ok          :
        title     : "Yes"
        callback  : -> credential.delete (err)->

          modal.destroy()

          unless KD.showError err
            item.destroy()

  shareItem: (item)->

    credential = item.getData()

    @emit "ShowShareCredentialFormFor", credential
    item.setClass 'sharing-item'

    @on 'sharingFormDestroyed', -> item.unsetClass 'sharing-item'

  showItemParticipants: (item)->

    credential = item.getData()
    credential.fetchUsers (err, users)->
      info err, users

  showItemContent: (item)->

    credential = item.getData()
    credential.fetchData (err, data)->
      unless KD.showError err

        data.meta.publicKey = credential.publicKey

        try

          cred = JSON.stringify data.meta, null, 2

        catch e

          warn e; log data
          return new KDNotificationView
            title: "An error occured"

        new KDModalView
          title    : credential.title
          subtitle : credential.provider
          content  : "<pre>#{cred}</pre>"


class AccountCredentialListItem extends KDListItemView

  JView.mixin @prototype

  constructor: (options = {}, data)->
    options.cssClass = KD.utils.curry "credential-item clearfix", options.cssClass
    super options, data

    delegate  = @getDelegate()
    { owner } = @getData()

    @deleteButton = new KDButtonView
      iconOnly : yes
      cssClass : "delete"
      callback : => delegate.deleteItem this

    @shareButton = new KDButtonView
      iconOnly : yes
      cssClass : "share"
      disabled : !owner
      callback : => delegate.shareItem this

    @showCredentialButton = new KDButtonView
      iconOnly : yes
      cssClass : "show"
      disabled : !owner
      callback : => delegate.showItemContent this

    @participantsButton = new KDButtonView
      iconOnly : yes
      cssClass : "participants"
      disabled : !owner
      callback : => delegate.showItemParticipants this

  pistachio:->
    """
    <div class='credential-info'>
      {h4{#(title)}} {p{#(provider)}}
    </div>
    <div class='buttons'>
      {{> @showCredentialButton}}{{> @deleteButton}}
      {{> @shareButton}}{{> @participantsButton}}
    </div>
    """
