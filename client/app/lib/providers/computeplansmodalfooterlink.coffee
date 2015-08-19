kd              = require 'kd'
CustomLinkView  = require '../customlinkview'
trackEvent      = require 'app/util/trackEvent'


module.exports = class ComputePlansModalFooterLink extends CustomLinkView

  constructor: (options = {}, data) ->

    options.href or= '/Pricing'
    options.click = ->
      trackEvent 'Upgrade your account, click',
          category : 'userInteraction'
          action   : 'clicks'
          label    : 'upgradeAccountOverlay'
          origin   : 'freeModal'

    super options, data