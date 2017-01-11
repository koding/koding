_  = require 'lodash'
articlize = require 'indefinite-article'
ContentModal = require 'app/components/contentModal'


module.exports = class MembershipRoleChangedModal extends ContentModal

  constructor: (options, { role, adminNick }) ->

    options = _.assign {}, options,
      title : 'Your team role has been changed!'
      overlay : yes
      width : 500
      cssClass : 'content-modal'
      content :
        """
        <p>
          @#{adminNick} made you #{articlize role} <strong font-weight="bold">#{role}</strong>,
          please refresh your browser for changes to take effect.
        </p>
        """
      buttons :
        'Reload page' :
          title : 'Reload Page'
          style : 'solid medium'
          callback : -> options.success()

    super options
