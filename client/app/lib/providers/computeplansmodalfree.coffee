kd = require 'kd'
KDView = kd.View
ComputePlansModal = require './computeplansmodal'
CustomLinkView = require '../customlinkview'
trackEvent = require 'app/util/trackEvent'


module.exports = class ComputePlansModalFree extends ComputePlansModal

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

    @addPricingLink 'Upgrade your account for more VMs RAM and Storage'


  addPricingLink: (title) ->

    @addSubView new CustomLinkView
      title    : title
      href     : '/Pricing'
      click    : ->
        trackEvent 'Upgrade your account, click',
          category : 'userInteraction'
          action   : 'clicks'
          label    : 'upgradeAccountOverlay'
          origin   : 'freeModal'
