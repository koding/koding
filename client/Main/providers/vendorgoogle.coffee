class VendorGoogle extends VendorBaseView

  VENDOR = "google"

  constructor:->
    super
      cssClass    : VENDOR
      vendorId    : VENDOR
    ,
      name        : "Google Compute Engine"
      description : """
        Run large-scale computing easily with Google's Compute Engine. Our
        Compute Engine is an IAAS that allows for scalable and efficient
        hosting configurations.
      """

    @_vendor = VENDOR

    @createFormView()