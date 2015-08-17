kd                    = require 'kd'
KDView                = kd.View
CustomLinkView        = require 'app/customlinkview'
ComputePlansModalFree = require 'app/providers/computeplansmodalfree'


module.exports = class LimitedVideoCollaborationFree extends ComputePlansModalFree


  viewAppended: ->

    @addSubView new KDView
      cssClass : 'message',
      partial  : """
        Free accounts are restricted to only one guest for video collaboration.
      """

    @addPricingLink 'Upgrade your account to any paid plan for unlimited video collaboration.'

