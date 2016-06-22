kd = require 'kd'
_  = require 'lodash'
contentModal = require 'app/components/contentModal'

module.exports = class AdminInviteModalView extends contentModal

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      title : options.title
      overlay : yes
      height : 'auto'
      cssClass : 'admin-invite-confirm-modal content-modal'
      buttons :
        Cancel :
          cssClass : 'cancel'
          title : 'Cancel'
          itemClass : kd.ButtonView
          style : 'solid medium'
          callback : -> options.cancel()
        Ok :
          title : "That'sFine"
          itemClass : kd.ButtonView
          cssClass : 'GenericButton confirm'
          style : 'solid medium'
          loader : { color: '#444444' }
          callback : -> options.success()

      content   : "<p>You're inviting <strong>#{options.admins.join ', '}</strong> as admin, they will have access to all team settings including your stack scripts (excluding your keys).</p>"

    super options, data
