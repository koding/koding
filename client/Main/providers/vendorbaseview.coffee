class VendorBaseView extends KDTabPaneView

  constructor:(options={}, data)->

    data?.description or= "We are still working on #{data.name} provider."
    options.cssClass    = KD.utils.curry "vendor-view", options.cssClass
    options.pistachio or= """
      {{> this.header}}
      {p{ #(description)}}
      {{> this.loader}}
      {{> this.content}}
    """

    super options, data

    @header = new KDHeaderView
      title : @getData().name
      type  : "medium"

    @content = new KDView
    @loader  = new KDLoaderView
      showLoader : @getOption('vendorId')?
      size       :
        width    : 40

  createFormView:->

    vendor = @getOption 'vendorId'

    @credentialBox  = new KDSelectBox
      name          : 'type'
      cssClass      : 'type-select hidden'
      selectOptions : [
        { title: "Loading #{vendor} credentials...", disabled: yes }
      ]
      callback      : (value) =>

        if value is "_add_"
          @credentialBox.hide()
          @form.setClass 'in'
          @instanceListView.hide()
        else
          @showInstanceList value

    @content.addSubView @credentialBox

    @form = ComputeProvider.generateAddCredentialFormFor vendor

    @form.on "Cancel", =>

      @form.unsetClass 'in'

      @credentialBox.setValue @_credOptions.first.title
      @credentialBox.show()

    @form.on "CredentialAdded", (credential)=>
      @form.unsetClass 'in'
      @paneSelected yes
      log "Added", { credential }

    @content.addSubView @form

    @instanceController = new KDListViewController
      viewOptions       :
        cssClass        : 'instance-list'
        wrapper         : yes
        itemClass       : CloudInstanceItemView
        itemOptions     : { vendor }
      noItemFoundWidget : new KDView
        partial         : "Instance list is not available at this time."

    @content.addSubView @instanceListView = @instanceController.getView()
    @instanceListView.hide()

    @instanceList = @instanceController.getListView()
    @instanceList.on "InstanceSelected", (instance)=>

      { name } = instance.getData()
      @_currentCredential

      ComputeProvider.create
        provider   : vendor
        credential : @_currentCredential
        name       : name
      , (err, res)->

        unless KD.showError err

          try

            packerTemplate = JSON.stringify res, null, 2

          catch e

            warn e; log res
            return new KDNotificationView
              title: "An error occured"

          new KDModalView
            content : "<pre>#{packerTemplate}</pre>"

  viewAppended:->
    super
    @on 'PaneDidShow', @bound 'paneSelected'

  showInstanceList:(credentialKey)->
    vendor = @getOption 'vendorId'

    @_currentCredential = credentialKey

    ComputeProvider.fetchAvailable
      provider   : vendor
      credential : credentialKey
    , (err, instances)=>

      if err

        @instanceController.noItemView.updatePartial \
          if err.name is "NotImplemented"
            "Listing instances for #{vendor} is not implemented yet."
          else
            "An error occured while listing instances for #{vendor}."

        warn err

      else if instances

        @instanceController.replaceAllItems instances

      @instanceListView.show()

  paneSelected:(force = no)->

    return if @_laoded and not force

    @loader.show()

    vendor = @getOption 'vendorId'
    ComputeProvider.credentialsFor vendor, (err, credentials = [])=>

      @loader.hide()

      return if KD.showError err

      if credentials.length is 0
        @credentialBox.hide()
        @instanceListView.hide()
        @form.buttons.Cancel.hide()
        @form.setClass 'in'
        @_laoded = no
        return

      @_laoded = yes

      log { credentials }

      @_credentials = {}
      @_credOptions = []

      for cred in credentials
        @_credentials[cred.publicKey] = cred
        @_credOptions.push
          title: cred.title, value: cred.publicKey

      @_credOptions.push
        title: "Add new credential...", value: "_add_"

      @credentialBox.removeSelectOptions()
      @credentialBox.setSelectOptions
        "Select credential..." : @_credOptions

      @credentialBox.show()
      @showInstanceList @_credOptions.first.value
      @instanceListView.show()
