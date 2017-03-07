kd = require 'kd'
ContentModal = require 'app/components/contentModal'
SingleGroupInfo = require './singlegroupinfo'
whoami = require 'app/util/whoami'
fetchMyRelativeGroups = require 'app/util/fetchMyRelativeGroups'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
verifyPassword = require 'app/util/verifyPassword'
showError = require 'app/util/showError'
pluralize = require 'pluralize'
require('./styl/deleteaccount.styl')

module.exports = class DeleteAccountModal extends ContentModal

  constructor: (options, groups) ->

    options = _.assign {}, options,
      title : 'Account Management!'
      overlay : yes
      width : 700
      cssClass : 'content-modal delete-account-modal'

    super options

    groupsCount = groups.length

    pronoun1 = if groupsCount is 1 then 'its' else 'their'
    pronoun2 = if groupsCount is 1 then 'it' else 'them'

    @main.addSubView new kd.CustomHTMLView
      tagName: 'p'
      partial: "
        <p>
          You can not delete your team because you own
          #{pluralize 'team', groupsCount, yes}.
          You must either transfer #{pronoun1}
          #{pluralize 'ownership', groupsCount, no} or delete #{pronoun2}
          from #{pronoun1} #{pluralize 'dashboard', groupsCount, no}.
        </p>
        <br />
        <p>
          These are the teams that you own:
        </p>"

    @main.addSubView teamsWrapper = new kd.CustomHTMLView
      cssClass: 'teamswrapper'

    groups.forEach (group) ->
      teamsWrapper.addSubView new SingleGroupInfo {}, group

    @addSubView footer = new kd.CustomHTMLView
      cssClass: 'modal-footer'

    footer.addSubView deleteAccount = new kd.ButtonView
      title    : 'Delete My Account'
      cssClass : 'GenericButton delete-account-button'
      callback : ->
        fetchMyRelativeGroups (err, groups) ->

          return if showError err

          return showError 'You are still owner in other groups.'  if groups.length

          { deleteAccountVerifyModal } = require 'app/flux/teams/actions'
          deleteAccountVerifyModal()
