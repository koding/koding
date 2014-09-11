class ComputePlansModal.Paid extends ComputePlansModal

  constructor:(options = {}, data)->

    options.cssClass = 'paid-plan'
    options.height   = 323

    super options, data

  viewAppended:->

    { usage, limits, plan } = @getOptions()

    @addSubView content = new KDView
      cssClass : 'container'

    remaining = Math.max 0, limits.total - usage.total

    content.addSubView title = new KDView
      cssClass : "modal-title"
      partial  : """
        Remaining VM slots:
          <strong>
            #{remaining}/#{limits.total}
          </strong>
      """

    title.setClass 'warn'  if usage.total >= limits.total

    content.addSubView storageContainer = new KDView
      cssClass : "storage-container"

    storageContainer.addSubView new KDView
      cssClass : "storage-title"
      partial  : "choose storage capacity"

    storageContainer.addSubView @storageSlider = new CustomPlanStorageSlider
      cssClass : 'storage-slider'
      maxValue : limits.storage * 2 # limits.storage - usage.storage
      minValue : 3
      handles  : [5]

    storageContainer.addSubView @usageTextView = new KDView

    content.addSubView @createVMButton = new KDButtonView
      title    : "Create your VM"
      style    : 'solid medium green'
      loader   : yes
      disabled : usage.total >= limits.total

    content.addSubView new CustomLinkView
      title    : 'Upgrade your account for more VMs RAM and Storage'
      href     : '/Pricing'

    @updateUsageText 5, usage, limits
    @storageSlider.on "ValueIsChanging", (val)=>
      @updateUsageText val, usage, limits

  updateUsageText: (val, usage, limits)->

    newUsage = usage.storage + val

    if newUsage > limits.storage
      @usageTextView.setClass 'warn'
      @createVMButton.disable()
    else
      @usageTextView.unsetClass 'warn'
      @createVMButton.enable()  unless usage.total >= limits.total

    @usageTextView.updatePartial """
      You will be using <strong>#{newUsage}GB/#{limits.storage}GB</strong> storage
    """