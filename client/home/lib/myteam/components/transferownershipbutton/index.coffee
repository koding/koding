$ = require 'jquery'
kd = require 'kd'
showError = require 'app/util/showError'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
verifyPassword = require 'app/util/verifyPassword'
whoami = require 'app/util/whoami'
require('./styl/transferownershipbutton.styl')


module.exports = class TransferOwnershipButton extends kd.CustomHTMLView

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry 'transferownershipbutton', options.cssClass

    super options, data

    group = @getData()

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
        ownershipBtn.updatePartial 'TRANSFER OWNERSHIP'
        ownershipBtn.unsetClass 'transfer-ready'

    @addSubView ownershipBtn = new kd.CustomHTMLView
      partial : 'TRANSFER OWNERSHIP'
      cssClass : 'transfer-ownership'
      click : =>

        if selection.getValue()
          return @verifyModal group, selection.getValue()

        group.fetchMembers (err, members) ->

          members = members
            .filter (mem) -> mem._id isnt whoami()._id
            .map (mem) -> { title: mem.profile.nickname,  value: mem._id }


          if members.length
            members.unshift { title: 'Select new owner', value: '' }
            cancelBtn.show()
            ownershipBtn.hide()
            selection.show()
            selection.setSelectOptions members
            selection.setValue ''
            ownershipBtn.updatePartial 'TRANSFER'
            ownershipBtn.setClass 'transfer-ready'
          else
            cancelBtn.show()
            members.unshift { title: 'There is no one in team', value: '' }
            selection.show()
            selection.setSelectOptions members
            ownershipBtn.hide()


  verifyModal: (group, accountId) ->

    username = $("[value='#{accountId}']").text()

    partial = "
      <p>
        <strong>CAUTION! </strong>You are going to transfer the ownership
        of your team with <strong>#{username}</strong>
      </p> <br>
      <p>You will become an admin of this team.</p>
      <p>If this team is using your credit card information for subscription, Please make sure
      you cancel the subscription before you delete your account.
      <p>Please enter <strong>current password</strong> into the field below to continue: </p>
    "

    new VerifyPasswordModal 'Confirm', partial, (currentPassword) =>
      verifyPassword currentPassword, (err) =>
        return  if showError err

        group.transferOwnership { accountId, currentPassword, slug: group.slug }, (err) =>
          return if showError err
          @destroy()
