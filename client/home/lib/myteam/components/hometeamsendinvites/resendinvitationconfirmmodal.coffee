kd = require 'kd'
_ = require 'lodash'
ContentModal = require 'app/components/contentModal'

module.exports = class ResendInvitationConfirmationModal extends ContentModal

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      title                   : 'Resend Invitation'
      overlay                 : yes
      height                  : 'auto'
      cssClass                : 'admin-invite-confirm-modal content-modal'
      buttons : {}

    options.buttons[options.cancelButtonText] =
      title: 'Cancel'
      cssClass : 'cancel'
      itemClass : kd.ButtonView
      style : 'solid medium'
      callback : -> options.cancel()

    options.buttons[options.resendButtonText] =
      title: 'Resend'
      itemClass : kd.ButtonView
      cssClass : 'GenericButton confirm'
      style : 'solid medium'
      loader : { color: '#444444' }
      callback : -> options.success()


    super options, data
