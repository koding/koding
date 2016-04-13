kd = require 'kd'
_  = require 'lodash'


module.exports = class AdminInviteModalView extends kd.ModalViewWithForms

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      title                   : options.title
      overlay                 : yes
      height                  : 'auto'
      cssClass                : 'admin-invite-confirm-modal'
      tabs                    :
        forms                 :
          confirm             :
            buttons           :
              "That's fine"   :
                itemClass     : kd.ButtonView
                cssClass      : 'confirm'
                style         : 'solid green medium'
                loader        : { color: '#444444' }
                callback      : => options.success()
              Cancel          :
                itemClass     : kd.ButtonView
                style         : 'solid medium'
                callback      : => options.cancel()
            fields            :
              planDetails     :
                type          : 'hidden'
                nextElement   :
                  planDetails :
                    cssClass  : 'content'
                    itemClass : kd.View
                    partial   : "You're inviting <strong>#{options.admins.join ', '}</strong> as admin, they will have access to all team settings including your stack scripts (excluding your keys)."

    super options, data
