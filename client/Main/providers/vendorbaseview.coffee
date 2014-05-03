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

  viewAppended:->
    super
    @on 'PaneDidShow', =>
      @loader.show()  if @getOption('vendorId')?
      @form?.unsetClass 'in'
      KD.utils.wait 1000, =>
        @form?.setClass 'in'
        @loader.hide()
