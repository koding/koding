class VendorGoogle extends VendorBaseView
  constructor:->
    super
      cssClass    : "google"
      vendorId    : "google"
    ,
      name        : "Google Compute Engine"
      description : """
        Run large-scale computing easily with Google's Compute Engine. Our
        Compute Engine is an IAAS that allows for scalable and efficient
        hosting configurations.
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

