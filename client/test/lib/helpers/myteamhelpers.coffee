helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'


module.exports =

  inviteUser: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    sendInvitesButton = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.primary.fr"

    browser
      .waitForElementVisible invitationsModalSelector, 20000

    userEmail = @fillInviteInputByIndex browser, 1
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

    @acceptConfirmModal browser, successMessage

    userEmail = @fillInviteInputByIndex browser, 3
    successMessage = "Invitation is sent to #{userEmail}"

    browser
      .pause 10000
      .waitForElementVisible sendInvitesButton, 5000
      .click sendInvitesButton

      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', successMessage



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

    @acceptConfirmModal browser, successMessage


  uploadCSV: (browser) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    uploadCSVButtonSelector = "#{invitationsModalSelector} .custom-link-view.HomeAppView--button.ft"
    message = 'Coming Soon!'

    browser
      .waitForElementVisible invitationsModalSelector, 20000
      .click uploadCSVButtonSelector
      .waitForElementVisible '.kdnotification', 10000
      .assert.containsText '.kdnotification', message
      .pause 2000

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


  acceptConfirmModal: (browser, successMessage) ->

    confirmModal = '.kdmodal.admin-invite-confirm-modal.kddraggable'
    confirmButton = '.kdmodal-content .kdbutton.confirm.solid.green.medium.w-loader'

    browser
      .element 'css selector', confirmModal, (result) ->

        if result.status is 0
          browser
            .pause 2000
            .waitForElementVisible confirmButton, 10000
            .click                 confirmButton
            .waitForElementVisible '.kdnotification', 10000
            .assert.containsText '.kdnotification', successMessage

  fillInviteInputByIndex: (browser, index, userEmail = null) ->

    invitationsModalSelector = '.HomeAppView--section.send-invites'
    emailInputSelector = "#{invitationsModalSelector} .ListView-row:nth-of-type(#{index}) .kdinput.text.user-email"
    userEmail ?= "#{helpers.getFakeText().split(' ')[0]}#{Date.now()}@kd.io"

    browser
      .waitForElementVisible emailInputSelector, 20000
      .setValue emailInputSelector, userEmail

    return userEmail
