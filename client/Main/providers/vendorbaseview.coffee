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

    @form = ComputeProvider.generateAddCredentialFormFor @_vendor

    @form.on "Cancel", -> @unsetClass 'in'
    @form.on "CredentialAdded", (credential)=>
      credential.owner = yes
      @form.unsetClass 'in'
      @addItem credential

    @content.addSubView @form

  viewAppended:->
    super
    @on 'PaneDidShow', @bound 'paneSelected'

  paneSelected:->

    ComputeProvider.credentialsFor @_vendor, (err, credentials = [])=>

      @loader.hide()

      unless KD.showError err

        if credentials.length > 0
          credential = credentials.first
          @content.addSubView new KDView
            partial: "#{credential.title}"
        else
          @form.setClass 'in'
