class VendorAmazon extends VendorBaseView
  constructor:->
    super
      cssClass    : "amazon"
      vendorId    : "amazon"
    ,
      name        : "Amazon"
      description : """
        Amazon Web Services offers reliable, scalable, and inexpensive
        cloud computing services. Free to join, pay only for what you use.
      """

    @form = new KDFormViewWithFields
      cssClass             : "form-view"
      fields               :
        accessKey          :
          placeholder      : "access key"
          name             : "accessKey"
          cssClass         : "thin"
        secret             :
          placeholder      : "secret"
          name             : "secret"
          type             : "password"
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

