kd = require 'kd'
_ = require 'lodash'
ContentModal = require 'app/components/contentModal'

module.exports = class AlreadyMemberInvitationModal extends ContentModal

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      title    : 'Invites Already Sent'
      overlay  : yes
      height   : 'auto'
      cssClass : 'admin-invite-confirm-modal content-modal'
      buttons :
        OK :
          title: 'OK'
          itemClass : kd.ButtonView
          style : 'solid medium'
          callback : -> options.success()

    super options, data
