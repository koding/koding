kd = require 'kd'
ContentModal = require 'app/components/contentModal'
SingleGroupInfo = require './singlegroupinfo'
whoami = require 'app/util/whoami'
fetchMyRelativeGroups = require 'app/util/fetchMyRelativeGroups'
require('./styl/deleteaccount.styl')

module.exports = class DeleteAccountModal extends ContentModal

  constructor: (options, groups) ->

    options = _.assign {}, options,
      title : 'Account Managnment!'
      overlay : yes
      width : 700
      cssClass : 'content-modal delete-account-modal'

    super options

    @main.addSubView new kd.CustomHTMLView
      tagName: 'p'
      partial: '
        <p>
          <strong>CAUTION!</strong>
          You can not delete your account if you are owner of any team. You must
          tranfer the ownership or delete the team.
          These are the teams that you are owner of.
        </p>
        <p>
          Transfering ownership makes you an admin of that team.
          You must login and save your keys before you delete your account.
        </p>
        <p>
          Delete team must be handled in the team so you will be redirected.
        </p>'

    @main.addSubView teamsWrapper = new kd.CustomHTMLView
      cssClass: 'teamswrapper'

    groups.forEach (group) ->
      teamsWrapper.addSubView new SingleGroupInfo {}, group

    @addSubView footer = new kd.CustomHTMLView
      cssClass: 'modal-footer'

    footer.addSubView deleteAccount = new kd.ButtonView
      title          : 'Delete Team And Account'
      cssClass       : 'GenericButton delete-account-button'
      callback       : ->
        fetchMyRelativeGroups (err, groups) ->

          groups = groups.filter (group) -> 'owner' in group.roles
          whoami().destroyAccount()  unless groups.length
