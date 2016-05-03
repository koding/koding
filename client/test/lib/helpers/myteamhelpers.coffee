helpers = require './helpers.js'
utils = require '../utils/utils.js'
teamsHelpers = require './teamshelpers.js'


module.exports =

  inviteUser: (browser, role) ->

    index = if role is 'member' then 2 else 1

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail

  inviteAll: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    newEmailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(4) .kdinput.text.user-email"
    newUserEmail = "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    successMessage = "All invitations are sent."

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    firstUserEmail = @fillInviteInputByIndex browser, 1
    secondUserEmail = @fillInviteInputByIndex browser, 2
    thirdUserEmail = @fillInviteInputByIndex browser, 3

    browser
      .pause 3000
      .waitForElementVisible newEmailInputSelector, 10000
      .setValue newEmailInputSelector, newUserEmail
      .pause 5000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

  uploadCSV: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    uploadCSVButtonSelector = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.ft"
    message = 'Coming Soon!'

    browser
      .waitForElementVisible invitationsModalSelector, 20000
      .click uploadCSVButtonSelector
    @assertConfirmation browser, message


  resendInvitation: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'

    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    index = if role is 'member' then 2 else 1

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .pause 2000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton
    @acceptConfirmModal browser if role is 'admin'
    @assertConfirmation browser, successMessage
    browser
      .pause 10000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    successMessage = "Invitation is resent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser

    if role is 'admin'
      browser
        .pause 2000
      @acceptConfirmModal browser
    @assertConfirmation browser, successMessage

    return userEmail


  newInviteFromResendModal: (browser, role) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"
    userEmail = @inviteUser browser, role
    index = if role is 'member' then 2 else 1
    browser
      .pause 5000
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, index, userEmail
    newEmail = @fillInviteInputByIndex browser, index+1
    successMessage = "Invitation is sent to #{newEmail}"

    browser
      .click sendInvitesButton
    @acceptConfirmModal browser  if role is 'admin'
    @rejectConfirmModal browser
    @assertConfirmation browser, successMessage


  rejectConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    cancelButton = '.kdmodal-content .kdbutton.solid.medium:nth-of-type(2)'
    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible cancelButton, 10000
            .click                 cancelButton


  acceptConfirmModal: (browser) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    confirmButton = '.kdmodal-content .kdbutton.confirm.solid.green.medium.w-loader'

    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible confirmButton, 10000
            .click                 confirmButton


  assertConfirmation: (browser, successMessage) ->

    browser
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', successMessage
      .pause 2000


  fillInviteInputByIndex: (browser, index, userEmail = null) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
    userEmail ?= "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"

    browser
      .waitForElementVisible emailInputSelector, 20000
      .setValue emailInputSelector, userEmail

    return userEmail


  logoutTeam: (browser, callback) ->

    browser
      .waitForElementVisible '.avatarview.avatar-image-wrapper', 20000
      .click '.avatarview.avatar-image-wrapper'
      .pause 2000
      .click '.avatarview.avatar-image-wrapper'
      .pause 2000
      .waitForElementVisible '.kdview.avatararea-popup.team', 20000
      .click '.kdview.avatararea-popup.team a[href="/Logout"]'
      .pause 5000, -> callback()


