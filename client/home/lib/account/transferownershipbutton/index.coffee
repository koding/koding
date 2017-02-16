$ = require 'jquery'
kd = require 'kd'
whoami = require 'app/util/whoami'
showError = require 'app/util/showError'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
verifyPassword = require 'app/util/verifyPassword'
require('./styl/transferownershipbutton.styl')


module.exports = class TransferOwnershipButton extends kd.CustomHTMLView

  constructor: (options, data) ->

    options = _.assign {}, options,
      cssClass : 'transferownershipbutton'

    super options, data

    group = data

    selectOptions = null

    @addSubView selection = new kd.SelectBox
      cssClass: 'select-box hidden'
      selectOptions: selectOptions
      callback: ->
        if selection.getValue()
          ownershipBtn.show()
        else
          ownershipBtn.hide()


    @addSubView cancelBtn = new kd.CustomHTMLView
      partial: 'Cancel'
      cssClass: 'cancel-btn hidden'
      click : ->
        @hide()
        selection.hide()
        ownershipBtn.show()
        selection.removeSelectOptions()

    @addSubView ownershipBtn = new kd.CustomHTMLView
      partial : 'Transfer Ownership'
      cssClass : 'transfer-ownership'
      click : =>

        if selection.getValue()
          return @verifyModal group, selection.getValue()

        group.fetchMembers (err, members) ->

          members = members
            .filter (mem) -> mem._id isnt whoami()._id
            .map (mem) -> { title: mem.profile.nickname,  value: mem._id }

          members.unshift { title: 'Select new owner', value: '' }

          if members.length > 1
            cancelBtn.show()
            ownershipBtn.hide()
            selection.show()
            selection.setSelectOptions members
            selection.setValue ''
          else
            cancelBtn.hide()
            ownershipBtn.destroy()
            new kd.NotificationView
              title: "You don't have any other team member, please delete team"
              duration: 3000


  verifyModal: (group, accountId) ->

    username = $("[value='#{accountId}']").text()

    partial = "<p>
        <strong>CAUTION! </strong>You are going to transfer the ownership
        of your team with <strong>#{username}</strong>
      </p> <br>
      <p>Please enter <strong>current password</strong> into the field below to continue: </p>"

    new VerifyPasswordModal 'Confirm', partial, (currentPassword) =>
      verifyPassword currentPassword, (err) =>
        return  if showError err

        group.transferOwnership { accountId, currentPassword, slug: group.slug }, (res) =>
          @emit 'destroy'
          @destroy()
