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
      log credentials

  loadView:->

    super

    view = @getView()
    view.on "ShowShareCredentialFormFor", @bound "showShareCredentialFormFor"

    vendorList = { }

    Vendors = ComputeProvider.vendors

    Object.keys(Vendors).forEach (vendor)=>
      vendorList[Vendors[vendor].title] =
        callback : =>
          @_addButtonMenu.destroy()
          @showAddCredentialFormFor vendor

    view.parent.addSubView addButton = new KDButtonView
      style     : "solid green small account-header-button"
      iconClass : "plus"
      iconOnly  : yes
      callback  : =>
        @_addButtonMenu = new KDContextMenu
          delegate    : addButton
          y           : addButton.getY() + 35
          x           : addButton.getX() - 142
          width       : 200
          arrow       :
            margin    : -4
            placement : "top"
        , vendorList

  showShareCredentialFormFor: (credential)->

    view = @getView().parent
    view.form?.destroy()

    view.form           = new KDFormViewWithFields
      cssClass          : "form-view"
      fields            :
        username        :
          label         : "User"
          type          : "hidden"
          nextElement   :
            userWrapper :
              itemClass : KDView
              cssClass  : "completed-items"
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
          callback      : -> view.form.destroy()

      callback          : (data)=>

        log "Here we go", data

        { usernames, owner } = data
        target = usernames.first

        unless target
          return new KDNotificationView
            title : "A user required to share credential with"

        { Save } = view.form.buttons
        Save.showLoader()

        credential.shareWith { target, owner }, (err)=>

          Save.hideLoader()

          unless KD.showError err
            view.form.destroy()
            @loadItems()


    {fields, inputs, buttons} = view.form

    @userController       = new KDAutoCompleteController
      form                : view.form
      name                : "username"
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
          KD.remote.api.JAccount.one query, (err, account)=>
            if not account
              @userController.showNoDataFound()
            else
              callback [account]
        else
          KD.remote.api.JAccount.byRelevance inputValue, {}, (err, accounts)->
            callback accounts

    fields.username.addSubView userRequestLineEdit = @userController.getView()
    @userController.on "ItemListChanged", (count)->
      userRequestLineEdit[if count is 0 then 'show' else 'hide']()

    view.addSubView view.form


  showAddCredentialFormFor: (vendor)->

    view = @getView().parent
    view.form?.destroy()

    fields          =
      title         :
        label       : "Title"
        placeholder : "title for this credential"

    Vendors = ComputeProvider.vendors

    Object.keys(Vendors[vendor].credentialFields).forEach (field)->
      fields[field] = _.clone Vendors[vendor].credentialFields[field]
      fields[field].required = yes

    view.form      = new KDFormViewWithFields
      cssClass     : "form-view"
      fields       : fields
      buttons      :
        Save       :
          title    : "Add credential"
          type     : "submit"
          style    : "solid green medium"
          loader   :
            color  : "#444444"
          callback : -> @hideLoader()
        Cancel     :
          type     : "cancel"
          style    : "solid medium"
          callback : -> view.form.destroy()
      callback     : (data)=>

        log "Here we go", data

        { Save } = view.form.buttons
        Save.showLoader()

        { title } = data
        delete data.title

        KD.remote.api.JCredential.create {
          vendor, title, meta: data
        }, (err, credential)=>

          Save.hideLoader()

          unless KD.showError err
            view.form.destroy()
            @loadItems()

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

  showItemContent: (item)->

    credential = item.getData()
    credential.fetchData (err, data)->
      unless KD.showError err

        try

          cred = JSON.stringify data.meta, null, 2

        catch e

          warn e; log data
          return new KDNotificationView
            title: "An error occured"

        new KDModalView
          content : "<code>#{cred}</code>"

class AccountCredentialListItem extends KDListItemView

  constructor: (options = {}, data)->
    options.cssClass = KD.utils.curry "credential-item", options.cssClass
    super options, data

    delegate = @getDelegate()

    @deleteButton = new KDButtonView
      title    : "Delete"
      cssClass : "solid small red"
      callback : => delegate.deleteItem this

    @shareButton = new KDButtonView
      title    : "Share"
      cssClass : "solid small green"
      disabled : !@getData().owner
      callback : => delegate.shareItem this

    @showCredentialButton = new KDButtonView
      title    : "Show Content"
      cssClass : "solid small green"
      disabled : !@getData().owner
      callback : => delegate.showItemContent this

  viewAppended: JView::viewAppended

  pistachio:->
    """
     {{#(vendor)}} - {{#(title)}} -- {{> @showCredentialButton}} --
     {{> @deleteButton}} -- {{> @shareButton}} --
     {{#(owner)}}
    """
