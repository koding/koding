class VendorView extends KDView

  constructor:->

    super cssClass: 'vendor'

    @vendorController = new KDListViewController
      selection    : yes
      viewOptions  :
        cssClass   : 'vendor-list'
        wrapper    : yes
        itemClass  : VendorItemView
    , items        : [
      { name : "Koding",       view : new VendorKoding }
      { name : "Google",       view : new VendorGoogle }
      { name : "Amazon",       view : new VendorAmazon }
      { name : "DigitalOcean", view : new VendorDigitalOcean }
      { name : "EngineYard",   view : new VendorEngineyard }
    ]

  viewAppended:->

    @mainView = new KDTabView
      cssClass : "vendor-mainview"
      hideHandleContainer : yes

    @vendorListView = new KDView

    @vendorListView.addSubView new KDHeaderView
      title : "Vendors"
      type : "medium"

    @vendorListView.addSubView @vendorController.getView()

    @addSubView @messagesSplit = new SplitViewWithOlderSiblings
      sizes     : ["200px",null]
      views     : [@vendorListView, @mainView]
      cssClass  : "vendor-split"
      resizable : no

    # Add vendor views to mainview
    for vendor in @vendorController.itemsOrdered
      @mainView.addPane vendor.getData().view

    # Add Welcome pane
    @mainView.addPane new VendorWelcomeView

    @vendorController.on "ItemSelectionPerformed", (controller, item)=>
      {view} = item.items.first.getData()
      @mainView.showPane view
