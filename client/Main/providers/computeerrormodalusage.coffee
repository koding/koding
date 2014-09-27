class ComputeErrorModal.Usage extends ComputeErrorModal

  viewAppended:->

    {message, upgradeMessage, plan} = @getOptions()

    plan ?= 'free'

    switch plan
      when "developer"
        message ?= "You already have one VM marked as always on. Your account plan only allows for one VM to be always on."
        upgradeMessage ?= "Please upgrade to get more always on VMs."
      when "professional"
        message ?= "You already have two VMs marked as an always on. Your account plan only allows for two VMs to be always on."
        upgradeMessage ?= "Please upgrade to get more always on VMs."
      when "super"
        message ?= "You already have five VMs marked as an always on. Your account plan only allows for five VMs to be always on. "
        upgradeMessage ?= "Please contact us if you want more storage as you are already on our largest capacity plan."
        upgradeLink = "mailto:sales@koding.com"
      else
        message ?= "Our free accounts do not allow you to run your VM in an always-on state."
        upgradeMessage ?= "Please upgrade to enable this feature."

    @addSubView content = new KDView
      cssClass : 'message'
      partial  : message

    @addSubView new CustomLinkView
      title    : upgradeMessage
      href     : upgradeLink ? '/Pricing'
