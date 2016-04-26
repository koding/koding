helpers = require '../helpers/helpers.js'
utils = require '../utils/utils.js'


module.exports =

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
