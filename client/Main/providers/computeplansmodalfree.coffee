class ComputePlansModal.Free extends ComputePlansModal

  constructor:(options = {}, data)->

    super
      cssClass : 'free-plan'
      message  : options.message ? "Free users are restricted to one VM.<br/>"

  viewAppended:->

    @addSubView content = new KDView
      cssClass : 'message'
      partial  : @getOption 'message'

    content.addSubView new CustomLinkView
      title    : 'Upgrade your account for more VMs RAM and Storage'
      href     : '/Pricing'
