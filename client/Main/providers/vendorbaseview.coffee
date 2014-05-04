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
      type : "medium"

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

  viewAppended:->
    super
    @on 'PaneDidShow', @bound 'paneSelected'

  paneSelected:->

    ComputeProvider.credentialsFor @_vendor, (err, credentials = [])=>

      @loader.hide()

      return if KD.showError err

      if credentials.length is 0
        @credentialBox.hide()
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
