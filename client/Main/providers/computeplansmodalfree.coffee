class ComputePlansModal.Free extends ComputePlansModal

  constructor:(options = {}, data)->

    options.cssClass = 'free-plan'
    super options, data


  viewAppended:->

    @addSubView content = new KDView
      cssClass     : 'message'
      partial      : {
        'free'     : "Free users are restricted to one VM.<br/>"
        'hobbyist' : "Hobbyist plan is restricted to only one VM. <br/>"
      }[@getOption 'plan']

    @addSubView new CustomLinkView
      title    : 'Upgrade your account for more VMs RAM and Storage'
      href     : '/Pricing'
