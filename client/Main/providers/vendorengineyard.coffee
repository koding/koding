class VendorEngineyard extends VendorBaseView

  VENDOR = "engineyard"

  constructor:->
    super
      cssClass    : VENDOR
      vendorId    : VENDOR
    ,
      name        : "EngineYard"
      description : """
        Spend less time worrying about operational tasks and
        more time focusing on your app.
      """

    @createFormView()