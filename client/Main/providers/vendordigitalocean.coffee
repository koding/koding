class VendorDigitalOcean extends VendorBaseView

  VENDOR = "digitalocean"

  constructor:->
    super
      cssClass    : VENDOR
      vendorId    : VENDOR
    ,
      name        : "DigitalOcean"
      description : """
        Deploy an 512MB RAM and 20GB SSD cloud server in 55
        seconds for $5/month. Simple, fast, scalable SSD cloud virtual servers.
      """

    @_vendor = VENDOR

    @createFormView()