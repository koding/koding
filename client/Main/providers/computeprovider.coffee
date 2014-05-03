
class ComputeProvider extends KDObject

  @vendors                   =

    custom                   :
      title                  : "Custom Credential"
      description            : """Custom credentials can include meta
                                 credentials for any service"""
      credentialFields       :
        credential           :
          label              : "Credential"
          placeholder        : "credential in JSON format"
          type               : "textarea"

    amazon                   :
      title                  : "AWS Credential"
      description            : "Amazon Web Services"
      credentialFields       :
        accessKeyId          :
          label              : "Access Key"
          placeholder        : "aws access key"
        secretAccessKey      :
          label              : "Secret Key"
          placeholder        : "aws secret key"
          type               : "password"
        region               :
          label              : "Region"
          placeholder        : "aws region"
          defaultValue       : "us-east-1"

    koding                   :
      title                  : "Koding Credential"
      description            : "Koding rulez."
      credentialFields       :
        username             :
          label              : "Username"
          placeholder        : "koding username"
        password             :
          label              : "Password"
          placeholder        : "koding password"
          type               : "password"

    google                   :
      title                  : "Google Cloud Credential"
      description            : "Google compute engine"
      credentialFields       :
        projectId            :
          label              : "Project Id"
          placeholder        : "project id in gce"
        clientSecretsContent :
          label              : "Client secrets"
          placeholder        : "content of the client_secrets.xxxxx.json"
          type               : "textarea"
        privateKeyContent    :
          label              : "Private Key"
          placeholder        : "content of the xxxxx-privatekey.pem"
          type               : "textarea"
        zone                 :
          label              : "Zone"
          placeholder        : "google zone"
          defaultValue       : "us-central1-a"

    engineyard               :
      title                  : "EngineYard Credential"
      description            : "EngineYard"
      credentialFields       :
        accountId            :
          label              : "Account Id"
          placeholder        : "account id in engineyard"
        secret               :
          label              : "Secret"
          placeholder        : "engineyard secret"
          type               : "password"

    digitalocean             :
      title                  : "Digitalocean Credential"
      description            : "Digitalocean droplets"
      credentialFields       :
        clientId             :
          label              : "Client Id"
          placeholder        : "client id in digitalocean"
        apiKey               :
          label              : "API Key"
          placeholder        : "digitalocean api key"

  @showProvidersModal = ->
    new KDModalView
      title        : 'Add Virtual Machine'
      cssClass     : 'vendor-modal'
      view         : new VendorView
      width        : 800
      overlay      : yes
      buttons      :
        create     :
          title    : "Create"
          style    : "modal-clean-green"
          callback : =>


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
      {
        name       : "Koding"
        view       : new VendorKoding
      }
      {
        name       : "Amazon"
        view       : new VendorAmazon
      }
      {
        name       : "DigitalOcean"
        view       : new VendorDigitalOcean
      }
      {
        name       : "EngineYard"
        view       : new VendorEngineyard
      }
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

class VendorItemView extends KDListItemView

  constructor:(options = {}, data)->

    options.cssClass = "#{data.name}"
    super options, data

  viewAppended: JView::viewAppended

  pistachio:-> ""


class VendorWelcomeView extends KDTabPaneView

  constructor:->
    super
      cssClass : "welcome-pane"
      partial  : """
        <h1>Vendors for your next Virtual Machine</h1>
        <p>Koding can work with popular service providers,
           and you can build your next server on one of them.</p>
        <p>Select a vendor from left to start.</p>
      """

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

class VendorKoding extends VendorBaseView
  constructor:->
    super
      cssClass : "koding"
    ,
      name     : "Koding"
      description : """
        Koding provides you a full featured vms which bundles all popular Web
        technologies, ready to use.
      """

  viewAppended:->
    super

    addVmSelection = new KDCustomHTMLView
      cssClass   : "new-vm-selection"

    addVmSelection.addSubView addVmSmall = new KDCustomHTMLView
      cssClass    : "add-vm-box selected"
      partial     :
        """
          <h3>Small <cite>1x</cite></h3>
          <ul>
            <li><strong>1</strong> CPU</li>
            <li><strong>1GB</strong> RAM</li>
            <li><strong>4GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Large <cite>2x</cite></h3>
          <ul>
            <li><strong>2</strong> CPU</li>
            <li><strong>2GB</strong> RAM</li>
            <li><strong>8GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView addVmExtraLarge = new KDCustomHTMLView
      cssClass    : "add-vm-box passive"
      partial     :
        """
          <h3>Extra Large <cite>3x</cite></h3>
          <ul>
            <li><strong>4</strong> CPU</li>
            <li><strong>4GB</strong> RAM</li>
            <li><strong>16GB</strong> Storage</li>
          </ul>
        """

    addVmSelection.addSubView comingSoonTitle = new KDCustomHTMLView
      cssClass     : "coming-soon-title"
      tagName      : "h5"
      partial      : "Coming soon..."

    @content.addSubView addVmSelection

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

class VendorEngineyard extends VendorBaseView
  constructor:->
    super
      cssClass    : "engineyard"
      vendorId    : "engineyard"
    ,
      name        : "EngineYard"
      description : """
        Spend less time worrying about operational tasks and
        more time focusing on your app.
      """
