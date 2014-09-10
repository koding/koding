class ComputePlansModal.Paid extends ComputePlansModal

  constructor:(options = {}, data)->

    super
      cssClass : 'paid-plan'
      height   : 323

  viewAppended:->

    @addSubView content = new KDView
      cssClass : 'container'

    content.addSubView title = new KDView
      cssClass : "modal-title"
      partial  : "Remaining VM slots: 4/6"

    content.addSubView storageContainer = new KDView
      cssClass : "storage-container"

    storageContainer.addSubView new KDView
      cssClass : "storage-title"
      partial  : "choose storage capacity"

    storageContainer.addSubView new CustomPlanStorageSlider
      cssClass : 'storage-slider'
      maxValue : 30
      handles  : [3]

    storageContainer.addSubView new KDView
      partial  : "You will be using 15GB/25GB storage"

    content.addSubView new KDButtonView
      title    : "Create your VM"
      style    : 'solid medium green'
      loader   : yes

    content.addSubView new CustomLinkView
      title    : 'Upgrade your account for more VMs RAM and Storage'
      href     : '/Pricing'
