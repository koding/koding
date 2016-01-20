kd                          = require 'kd'
KDView                      = kd.View
KDModalView                 = kd.ModalView
CustomLinkView              = require 'app/customlinkview'
ComputePlansModalFooterLink = require 'app/providers/computeplansmodalfooterlink'


MESSAGES = {
  free : 'Free accounts are restricted to only one guest for video collaboration.'
}


module.exports = class LimitedVideoCollaborationModal extends KDModalView


  constructor: (options = {}, data) ->

    options.cssClass = 'free-plan computeplan-modal env-modal'
    options.width   ?= 336
    options.overlay ?= yes
    options.plan   or= 'free'

    super options, data


  viewAppended: ->

    plan = @getOption 'plan'

    @addSubView new KDView
      cssClass : 'message',
      partial  : MESSAGES[plan]

    @addSubView new ComputePlansModalFooterLink
      title : 'Upgrade your account to any paid plan for unlimited video collaboration.'
