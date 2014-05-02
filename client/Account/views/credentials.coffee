Vendors =

  custom                   :
    title                  : "Custom Credential"
    description            : """Custom credentials can include meta
                               credentials for any service"""
    credentialFields       :
      credential           :
        label              : "Credential"
        placeholder        : "credential in JSON format"
        type               : "textarea"

  amazon                   :
    title                  : "AWS Credential"
    description            : "Amazon Web Services"
    credentialFields       :
      accessKeyId          :
        label              : "Access Key"
        placeholder        : "aws access key"
      secretAccessKey      :
        label              : "Secret Key"
        placeholder        : "aws secret key"
        type               : "password"
      region               :
        label              : "Region"
        placeholder        : "aws region"
        defaultValue       : "us-east-1"

  koding                   :
    title                  : "Koding Credential"
    description            : "Koding rulez."
    credentialFields       :
      username             :
        label              : "Username"
        placeholder        : "koding username"
      password             :
        label              : "Password"
        placeholder        : "koding password"
        type               : "password"

  google                   :
    title                  : "Google Cloud Credential"
    description            : "Google compute engine"
    credentialFields       :
      projectId            :
        label              : "Project Id"
        placeholder        : "project id in gce"
      clientSecretsContent :
        label              : "Client secrets"
        placeholder        : "content of the client_secrets.xxxxx.json"
        type               : "textarea"
      privateKeyContent    :
        label              : "Private Key"
        placeholder        : "content of the xxxxx-privatekey.pem"
        type               : "textarea"
      zone                 :
        label              : "Zone"
        placeholder        : "google zone"
        defaultValue       : "us-central1-a"

  engineyard               :
    title                  : "EngineYard Credential"
    description            : "EngineYard"
    credentialFields       :
      accountId            :
        label              : "Account Id"
        placeholder        : "account id in engineyard"
      secret               :
        label              : "Secret"
        placeholder        : "engineyard secret"
        type               : "password"

  digitalocean             :
    title                  : "Digitalocean Credential"
    description            : "Digitalocean droplets"
    credentialFields       :
      clientId             :
        label              : "Client Id"
        placeholder        : "client id in digitalocean"
      apiKey               :
        label              : "API Key"
        placeholder        : "digitalocean api key"


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

  viewAppended: JView::viewAppended

  pistachio:->
    """
     {{#(vendor)}} - {{#(title)}} --
     {{> @deleteButton}} -- {{> @shareButton}} --
     {{#(owner)}}
    """
