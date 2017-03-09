$ = require 'jquery'
kd = require 'kd'
showError = require 'app/util/showError'
VerifyPasswordModal = require 'app/commonviews/verifypasswordmodal'
verifyPassword = require 'app/util/verifyPassword'
whoami = require 'app/util/whoami'
{ allUsers } = require 'app/flux/socialapi/getters'
require('./styl/transferownershipbutton.styl')


module.exports = class TransferOwnershipButton extends kd.CustomHTMLView

  constructor: (options, data) ->

    options.cssClass = kd.utils.curry 'transferownershipbutton', options.cssClass

    super options, data

    group = @getData()
    { currentGroup } = @getOptions()

    @members = []

    if currentGroup
      kd.singletons.reactor.observe allUsers, (members) =>

        members = Object.values members.toJSON()
        @filterMembers members
        @transferNotPossible?.destroy()
        @ownershipBtn?.destroy()
        @addTransferButton()

    else
      group.fetchMembers (err, members) =>
        @filterMembers members
        @addTransferButton()

    @addSubViews()


  filterMembers: (members) ->

    @members = members
      .filter (mem) -> mem._id isnt whoami()._id
      .map (mem) -> { title: mem.profile.nickname,  value: mem._id }

    @members.unshift { title: 'Select new owner', value: '' }  if @members.length

  addSubViews: ->

    selectOptions = null

    @addSubView @selection = new kd.SelectBox
      cssClass: 'select-box hidden'
      selectOptions: selectOptions
      callback: =>
        if @selection.getValue()
          @ownershipBtn.show()
        else
          @ownershipBtn.hide()

    @addSubView @cancelBtn = new kd.CustomHTMLView
      partial: 'Cancel'
      cssClass: 'cancel-btn hidden'
      click : =>
        @cancelBtn.hide()
        @selection.hide()
        @ownershipBtn.show()
        @selection.removeSelectOptions()
        @ownershipBtn.updatePartial 'TRANSFER OWNERSHIP'
        @ownershipBtn.unsetClass 'transfer-ready'


  addTransferButton: ->

    unless @members.length
      @addSubView @transferNotPossible = new kd.CustomHTMLView
        partial: 'Transfer not possible'
        cssClass : 'transfer-ownership-not-possible'

      @transferNotPossible.addSubView new kd.CustomHTMLView
        cssClass: 'transfernotpossible'
        tooltip     :
          title     : 'There is no one except you in this team'
          placement : 'top'
    else

      group = @getData()

      @addSubView @ownershipBtn = new kd.CustomHTMLView
        partial : 'TRANSFER OWNERSHIP'
        cssClass : 'transfer-ownership'
        click : =>

          if @selection.getValue()
            return @verifyModal group, @selection.getValue()

          @cancelBtn.show()
          @ownershipBtn.hide()
          @selection.show()
          @selection.setSelectOptions @members
          @selection.setValue ''
          @ownershipBtn.updatePartial 'TRANSFER'
          @ownershipBtn.setClass 'transfer-ready'



  verifyModal: (group, accountId) ->

    username = $("[value='#{accountId}']").text()

    partial = "
      <p>
        You are going to transfer the ownership of your team to @#{username}.
        After the transfer, you will become an admin of this team.
      </p> <br/>
      <p>
        <strong>CAUTION! </strong>If this team is using your credit card,
        transferring ownership won't affect the billing settings.
        You may want to remove your card or cancel the subscription,
        if you don't want to be charged in the future.
      </p> <br/>
      <p>Please enter <strong>your password</strong> to continue: </p>
    "

    new VerifyPasswordModal 'Confirm', partial, (currentPassword) =>
      verifyPassword currentPassword, (err) =>
        return  if showError err

        group.transferOwnership { accountId, currentPassword, slug: group.slug }, (err) =>
          return if showError err
          @destroy()
