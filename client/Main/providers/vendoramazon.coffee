class VendorAmazon extends VendorBaseView

  VENDOR = 'amazon'

  constructor:->
    super
      cssClass    : VENDOR
      vendorId    : VENDOR
    ,
      name        : "Amazon"
      description : """
        Amazon Web Services offers reliable, scalable, and inexpensive
        cloud computing services. Free to join, pay only for what you use.
      """

    @_vendor = VENDOR

    @createFormView()