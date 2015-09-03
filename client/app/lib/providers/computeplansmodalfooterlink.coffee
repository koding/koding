kd              = require 'kd'
trackEvent      = require 'app/util/trackEvent'
CustomLinkView  = require '../customlinkview'


module.exports = class ComputePlansModalFooterLink extends CustomLinkView


  constructor: (options = {}, data) ->

    options.href or= '/Pricing'

    super options, data


  click: ->

    trackEvent 'Upgrade your account, click',
      category : 'userInteraction'
      action   : 'clicks'
      label    : 'upgradeAccountOverlay'
      origin   : 'freeModal'
