helpers = require './helpers.js'
assert  = require 'assert'

messagePane = '.message-pane.privatemessage'
notStartedButtonSelector = '.status-bar a.share.not-started'

module.exports =

  startSession: (browser) ->

    shareButtonSelector = '.status-bar a.share:not(.loading)'
    chatViewSelector    = '.chat-view.onboarding'
    startButtonSelector = '.chat-view.onboarding .buttons button.start-session'

    helpers.beginTest(browser)
    helpers.waitForVMRunning(browser)

    browser
      .waitForElementVisible   shareButtonSelector, 20000
      .element 'css selector', notStartedButtonSelector, (result) =>
          if result.status is 0
            console.log 'session is not started'
            browser
              .click                  shareButtonSelector
              .waitForElementVisible  chatViewSelector, 20000
              .waitForElementVisible  startButtonSelector, 20000
              .click                  startButtonSelector
          else
            console.log 'session is active'

      browser
        .waitForElementVisible  messagePane, 20000 # Assertion
        .waitForElementVisible  '.status-bar a.share.active', 20000 # Assertion


  endSessionFromStatusBar: (browser) ->

    statusBarSelector       = '.status-bar .collab-status'
    buttonContainerSelector = statusBarSelector + ' .button-container'

    browser
      .waitForElementVisible  statusBarSelector, 20000
      .waitForElementVisible  statusBarSelector + ' span', 20000
      .click                  statusBarSelector + ' span'
      .waitForElementVisible  buttonContainerSelector, 20000
      .click                  buttonContainerSelector + ' button.end-session'

    @endSessionModal(browser)


  endSessionFromChat: (browser) ->

    @openChatSettingsMenu(browser)

    browser
      .waitForElementVisible  '.chat-dropdown li.end-session', 20000
      .click                  '.chat-dropdown li.end-session'

    @endSessionModal(browser)


  endSessionModal: (browser) ->

    buttonsSelector = '.kdmodal .kdmodal-buttons'

    browser
      .waitForElementVisible  '.with-buttons', 20000
      .waitForElementVisible  buttonsSelector, 20000
      .click                  buttonsSelector + ' button.green'
      .waitForElementVisible  notStartedButtonSelector, 20000 # Assertion


  openChatSettingsMenu: (browser) ->

    chatSettingsIcon = messagePane + ' .general-header .chat-dropdown .chevron'

    browser
      .waitForElementVisible  messagePane, 20000
      .waitForElementVisible  messagePane + ' .general-header', 20000
      .click                  messagePane + ' .general-header'
      .waitForElementVisible  chatSettingsIcon, 20000
      .click                  chatSettingsIcon
