class VendorDigitalOcean extends VendorBaseView
  constructor:->
    super
      cssClass    : "digitalOcean"
      vendorId    : "digitalocean"
    ,
      name        : "DigitalOcean"
      description : """
        Deploy an 512MB RAM and 20GB SSD cloud server in 55
        seconds for $5/month. Simple, fast, scalable SSD cloud virtual servers.
      """

    @form = new KDFormViewWithFields
      cssClass             : "form-view"
      fields               :
        clientId           :
          placeholder      : "client id"
          name             : "clientId"
          cssClass         : "thin"
        apiKey             :
          placeholder      : "api key"
          name             : "apiKey"
          cssClass         : "thin"
      buttons              :
        Save               :
          title            : "Add account"
          type             : "submit"
          cssClass         : "profile-save-changes"
          style            : "solid green medium"
          loader           : yes
      callback             : (cb)=>
        alert "update"; @form.buttons.Save.hideLoader()

    @content.addSubView @form

