kd = require 'kd'
_ = require 'lodash'


module.exports = class ResendInvitationConfirmationModal extends kd.ModalViewWithForms

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      title                   : 'Resend invitation'
      overlay                 : yes
      height                  : 'auto'
      cssClass                : 'admin-invite-confirm-modal'
      tabs                    :
        forms                 :
          confirm             :
            buttons           :
              "#{options.resendButtonText}" :
                itemClass     : kd.ButtonView
                cssClass      : 'confirm'
                style         : 'solid green medium'
                loader        : { color: '#444444' }
                callback      : -> options.success()
              "#{options.cancelButtonText}" :
                itemClass     : kd.ButtonView
                style         : 'solid medium'
                callback      : -> options.cancel()
            fields            :
              planDetails     :
                type          : 'hidden'
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : options.partial

    super options, data
