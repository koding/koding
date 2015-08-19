kd                    = require 'kd'
KDView                = kd.View
CustomLinkView        = require 'app/customlinkview'
ComputePlansModalFree = require 'app/providers/computeplansmodalfree'


MESSAGES = {
  free : 'Free accounts are restricted to only one guest for video collaboration.'
}


module.exports = class LimitedVideoCollaborationModal extends ComputePlansModalFree


  constructor: (options = {}, data) ->

    super options, data


  viewAppended: ->

    plan = @getOption 'plan'

    @addSubView new KDView
      cssClass : 'message',
      partial  : MESSAGES[plan]

    @addPricingLink 'Upgrade your account to any paid plan for unlimited video collaboration.'

